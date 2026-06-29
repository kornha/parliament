import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:political_think/games/gemtd/gemtdgame/ability/ability.dart';
import 'package:political_think/games/gemtd/gemtdgame/ability/buff.dart' as bf;
import 'package:political_think/games/gemtd/gemtdgame/base/game_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gem_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/weapon_settings.dart';
import 'package:political_think/games/gemtd/gemtdgame/enemy/enemy_component.dart';

import '../../city_config.dart';

// MENA — Religion / support region.
// Spine — Religion: every tower buffs nearby allies' damage. Lebanon is the pure
// spine; the higher tiers layer their own twist on top. North Africa (Morocco,
// Egypt) folds into MENA. Cedars (buff-amplify) and Venture Capitalism are cut.
// Lebanon(Religion) -> Morocco(Sandstorm: AoE damage) -> Egypt(Sphinx: curse)
// -> Saudi Arabia(Black Gold: oil) -> UAE(Burj Khalifa: bounty aura)
// -> Israel(Light unto the Nations: strong board-wide ally damage buff).

const mena_cities = <CityConfig>{
  lebanon,
  morocco,
  egypt,
  saudiArabia,
  uae,
  israel,
};

const lebanon = (level: 1, city: "Lebanon", countryCode: "LB");
const morocco = (level: 2, city: "Morocco", countryCode: "MA");
const egypt = (level: 3, city: "Egypt", countryCode: "EG");
const saudiArabia = (level: 4, city: "Saudi Arabia", countryCode: "SA");
const uae = (level: 5, city: "UAE", countryCode: "AE");
const israel = (level: 6, city: "Israel", countryCode: "IL");

class Mena extends GemComponent {
  Mena({Vector2? position, bool hidden = false})
      : super(position: position, hideSprite: hidden);

  @override
  GemAttributes get settings =>
      MenaSettings(cityConfig: mena_cities.getCityConfigByLevelOrLast(level));

  @override
  get currentImagePath => "flags/${countryCodes.first.toLowerCase()}.png";

  @override
  Future<void>? onLoad() async {
    await super.onLoad();
  }
}

class MenaSettings extends GemAttributes {
  MenaSettings({required this.cityConfig});

  final CityConfig cityConfig;

  @override
  CityType gemType = CityType.MENA;

  @override
  int projectileColumns(level) => 1;

  // Support region: pure auras (no attack). Morocco (level 2 — Sandstorm) is the
  // lone attacker, firing its periodic AoE damage. Israel (level 6) reaches far.
  @override
  double baseRange(int level) => level == 6 ? 3.5 : 2.5;

  @override
  double baseDamage(int level) => level == 2 ? 3.0 + level * 1.5 : 0.0;

  @override
  double baseAttackSpeed(int level) => level == 2 ? 1.0 : 0.0;

  @override
  int projectileRows(level) => 6;

  @override
  String get projectilePath => "weapon/chevron.png";

  @override
  double get projectileSizeX => 0.5;

  @override
  double get projectileSizeY => 0.5;

  @override
  late List<String> names = [...mena_cities.map((e) => e.city)];

  @override
  List<String> countryCodes(int level) => [cityConfig.countryCode];

  @override
  Set<Ability> abilities(int level, GemComponent caster) {
    final abilities = {...mena_abilities(this, level, caster, cityConfig)};
    abilities.forEach((a) {
      a.gemType = gemType;
      a.buff?.gemType = gemType;
    });
    return abilities;
  }
}

Set<Ability> mena_abilities(MenaSettings settings, int level,
        GemComponent caster, CityConfig config) =>
    switch (config) {
      lebanon => {
          Religion(level: level, caster: caster),
        },
      morocco => {
          Religion(level: level, caster: caster),
          Sandstorm(level: level, caster: caster),
        },
      egypt => {
          Religion(level: level, caster: caster),
          Sphinx(level: level, caster: caster),
        },
      saudiArabia => {
          Religion(level: level, caster: caster),
          BlackGold(level: level, caster: caster),
        },
      uae => {
          Religion(level: level, caster: caster),
          BurjKhalifa(level: level, caster: caster),
        },
      israel => {
          LightUntoNations(level: level, caster: caster),
        },
      _ => {
          Religion(level: level, caster: caster),
        },
    };

// Morocco — Sandstorm: a periodic AoE that fires at every enemy in range. Pure
// area damage, no slow — MENA's area-damage tower.
class Sandstorm extends Ability {
  Sandstorm({required super.caster, required super.level});

  @override
  String name = "Sandstorm";

  @override
  String description = "Periodically scours all enemies in range for damage.";

  @override
  String get subDescription => "Hits every enemy in range.";

  @override
  bool get canAttack => false;

  @override
  IconData icon = FontAwesomeIcons.wind.data;

  @override
  CityType gemType = CityType.MENA;

  @override
  GameComponent? onEnemyAttack(GemComponent gem, EnemyComponent primaryTarget,
      Set<GameComponent> targets) {
    for (var e in targets) {
      gem.fire(e as EnemyComponent);
    }
    return null;
  }
}

// UAE — Burj Khalifa: a bounty aura — enemies in range yield far more gold (the
// original "Golden Souk" mechanic).
class BurjKhalifa extends Ability {
  BurjKhalifa({required super.caster, required super.level});

  @override
  String name = "Burj Khalifa";

  @override
  bf.Buff? get buff => bf.BountyMultiple(caster: caster, level: level)
    ..name = name
    ..icon = icon
    ..gemType = gemType;

  @override
  String description = "Increases the bounty on enemies in range.";

  @override
  String get subDescription =>
      "${bf.BountyMultiple.defaultMultipliers.join("/")}x bounty.";

  @override
  bool get canAttack => false;

  @override
  bool get enemiesAura => true;

  @override
  CityType gemType = CityType.MENA;

  @override
  IconData icon = FontAwesomeIcons.coins.data;
}

// Israel — Light unto the Nations: the capstone spine — a strong, far-reaching
// ally damage buff (Religion, perfected).
class LightUntoNations extends Ability {
  LightUntoNations({required super.caster, required super.level});

  static const damageBuffPerLevel = [1.4, 1.5, 1.6, 1.7, 1.8, 2.0];

  @override
  String name = "Light unto the Nations";

  @override
  bf.Buff? get buff => bf.DamageMultiple(
        caster: caster,
        level: level,
        multipliersPerLevel: damageBuffPerLevel,
      )
        ..name = name
        ..icon = icon
        ..gemType = gemType;

  @override
  String description =
      "Greatly increases the attack damage of nearby allied countries.";

  @override
  String get subDescription =>
      "${damageBuffPerLevel.map((e) => "${(e * 100).toStringAsFixed(0)}%").join("/")} ally damage.";

  @override
  bool get canAttack => false;

  @override
  bool get alliesAura => true;

  @override
  CityType gemType = CityType.MENA;

  @override
  IconData icon = FontAwesomeIcons.starOfDavid.data;
}
