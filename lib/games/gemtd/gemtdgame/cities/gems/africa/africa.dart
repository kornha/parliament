import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:political_think/games/gemtd/common/extensions.dart';
import 'package:political_think/games/gemtd/gemtdgame/ability/ability.dart';
import 'package:political_think/games/gemtd/gemtdgame/ability/buff.dart' as bf;
import 'package:political_think/games/gemtd/gemtdgame/base/game_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gem_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/weapon_settings.dart';
import 'package:political_think/games/gemtd/gemtdgame/enemy/enemy_component.dart';

import '../../city_config.dart';

part 'africa_abilities.dart';
part 'africa_cities.dart';

class Africa extends GemComponent {
  Africa({super.position});

  @override
  GemAttributes get settings => AfricaSettings(
      cityConfig: africa_cities.getCityConfigByLevelOrLast(level));

  @override
  get currentImagePath => "city/${name.toLowerCase()}.png";
}

class AfricaSettings extends GemAttributes {
  AfricaSettings({required this.cityConfig});

  final CityConfig cityConfig;

  @override
  CityType gemType = CityType.AFRICA;

  @override
  late List<String> names = [...africa_cities.map((e) => e.city)];

  @override
  List<String> countryCodes(int level) => [cityConfig.countryCode];

  // Lagos (Afrobeat) fires invisible, fast, frequent, low-damage shots.
  @override
  String get projectilePath =>
      cityConfig == lagos ? "weapon/empty_bullet.png" : "weapon/chevron.png";

  // Nairobi's Stampede pierces a column of enemies.
  @override
  bool get canHitIntermediateTargets => cityConfig == nairobi;

  @override
  int projectileColumns(level) => 1;

  @override
  int projectileRows(level) => cityConfig == lagos ? 1 : 6;

  @override
  double get projectileSizeX => 0.5;

  @override
  double get projectileSizeY => 0.5;

  @override
  bool get projectLoop => false;

  @override
  double get projectileSpeed => switch (cityConfig) {
        lagos => 9.0,
        nairobi => 6.0,
        _ => 4.5,
      };

  @override
  String get explosionImage =>
      cityConfig == lagos ? "weapon/coinbase_explosion.png" : "weapon/auto_explosion.png";

  @override
  int get explosionColumns => cityConfig == lagos ? 6 : 1;

  @override
  int get explosionRows => 1;

  @override
  double get explosionSizeX => 0.9;

  @override
  double get explosionSizeY => 0.9;

  @override
  double baseRange(int level) => switch (cityConfig) {
        nairobi => 4.0, // long lane for the charge
        kinshasa => 2.5, // electrocute aura
        addis_ababa => 3.0, // poison range
        _ => 3.0, // lagos / johannesburg / cape town
      };

  @override
  double baseAttackSpeed(int level) => switch (cityConfig) {
        lagos => 3.5, // machine-gun
        nairobi => 0.4, // slow heavy charge
        kinshasa => 0.0, // aura, no attack
        addis_ababa => 1.2, // steady poison shots
        _ => 1.0, // johannesburg / cape town
      };

  @override
  double baseDamage(int level) => switch (cityConfig) {
        lagos => 0.6 + level * 0.2, // low (machine-gun)
        nairobi => 4.0 + level * 2.0, // heavy charge
        kinshasa => 0.0, // damage comes from the Cobalt aura buff
        addis_ababa => 1.5 + level * 0.5, // light hit; Venom DoT does the rest
        cape_town => 1.0, // the bite (% current HP) is the real damage
        _ => 2.0 + level * 0.8, // johannesburg
      };

  @override
  Set<Ability> abilities(int level, covariant Africa caster) {
    final abilities = {...africa_abilities(this, level, caster, cityConfig)};
    abilities.forEach((a) {
      a.gemType = gemType;
      a.buff?.gemType = gemType;
    });
    return abilities;
  }
}
