import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:political_think/games/gemtd/common/extensions.dart';
import 'package:political_think/games/gemtd/gemtdgame/ability/ability.dart';
import 'package:political_think/games/gemtd/gemtdgame/base/game_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gem_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gems/samerica.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/weapon_settings.dart';
import 'package:political_think/games/gemtd/gemtdgame/enemy/enemy_component.dart';

// S. America special — Garra Charrúa: the giant-killer. Every hit tears a
// percentage of the enemy's MAX health.
// Recipe: Argentina + Japan + Taiwan (small nations beside giants build the
// tower that kills giants).
class Uruguay extends GemComponent {
  Uruguay({Vector2? position}) : super(position: position);

  @override
  GemAttributes settings = UruguaySettings();

  @override
  get currentImagePath => "flags/${countryCodes.first.toLowerCase()}.png";

  @override
  int get level => 6;
}

class UruguaySettings extends GemAttributes {
  @override
  CityType gemType = CityType.SAMERICA;

  final _base = SAmerica()..level = 6;

  @override
  List<String> names = ["Uruguay"];

  @override
  String name(int level) => names[0];

  @override
  List<String> countryCodes(int level) => ["UY"];

  @override
  double baseAttackSpeed(int level) => _base.settings.baseAttackSpeed(level);
  @override
  double baseRange(int level) => _base.settings.baseRange(level);
  @override
  double baseDamage(int level) => _base.settings.baseDamage(level);
  @override
  double get projectileSpeed => _base.settings.projectileSpeed;
  @override
  String get projectilePath => _base.settings.projectilePath;
  @override
  double get projectileSizeX => _base.settings.projectileSizeX;
  @override
  double get projectileSizeY => _base.settings.projectileSizeY;
  @override
  int projectileColumns(level) => _base.settings.projectileColumns(level);
  @override
  int projectileRows(level) => _base.settings.projectileRows(level);
  @override
  bool get projectLoop => _base.settings.projectLoop;
  @override
  bool get aoe => _base.settings.aoe;
  @override
  String get explosionImage => _base.settings.explosionImage;
  @override
  int get explosionColumns => _base.settings.explosionColumns;
  @override
  int get explosionRows => _base.settings.explosionRows;
  @override
  double get explosionSizeX => _base.settings.explosionSizeX;
  @override
  double get explosionSizeY => _base.settings.explosionSizeY;

  @override
  Set<Ability> abilities(int level, GemComponent caster) {
    final a = {GarraCharrua(level: level, caster: caster)};
    for (final ab in a) {
      ab.gemType = gemType;
      ab.buff?.gemType = gemType;
    }
    return a;
  }
}

// Garra Charrúa: each hit tears away a percentage of the enemy's MAXIMUM
// health — unlike Great White's current-HP bite, this stays full-strength
// as the target falls. The bigger they are, the harder it hits.
class GarraCharrua extends Ability {
  GarraCharrua({required super.caster, required super.level});

  static const pctPerLevel = [0.010, 0.013, 0.016, 0.019, 0.022, 0.025];

  @override
  GameComponent? onEnemyAttack(GemComponent gem, EnemyComponent primaryTarget,
      Set<GameComponent> targets) {
    final bite = primaryTarget.maxLife * pctPerLevel.getByLevel(level);
    if (bite > 0) primaryTarget.receiveDamage(bite, {}, gem);
    return null;
  }

  @override
  String name = "Garra Charrúa";

  @override
  String description =
      "Every hit tears away a percentage of the enemy's maximum health — "
      "the giant-killer.";

  @override
  String get subDescription =>
      "${pctPerLevel.map((e) => "${(e * 100).toStringAsFixed(1)}%").join("/")} max HP per hit.";

  @override
  IconData icon = FontAwesomeIcons.handFist.data;

  @override
  CityType gemType = CityType.SAMERICA;
}
