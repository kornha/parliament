import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:political_think/games/gemtd/common/extensions.dart';
import 'package:political_think/games/gemtd/gemtdgame/ability/ability.dart';
import 'package:political_think/games/gemtd/gemtdgame/base/game_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gem_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/weapon_settings.dart';
import 'package:political_think/games/gemtd/gemtdgame/enemy/enemy_component.dart';

// MENA special — Ottoman: all who pass through the empire pay tribute.
// Recipe: Jamaica + Brazil + Ethiopia (the coffee lands build the
// civilization that invented the coffeehouse).
class Turkey extends GemComponent {
  Turkey({Vector2? position}) : super(position: position);

  @override
  GemAttributes settings = TurkeySettings();

  @override
  get currentImagePath => "flags/${countryCodes.first.toLowerCase()}.png";

  @override
  int get level => 6;
}

class TurkeySettings extends GemAttributes {
  @override
  CityType gemType = CityType.MENA;

  @override
  List<String> names = ["Turkey"];

  @override
  String name(int level) => names[0];

  @override
  List<String> countryCodes(int level) => ["TR"];

  @override
  double baseAttackSpeed(int level) => 0.9;
  @override
  double baseRange(int level) => 2.6;
  @override
  double baseDamage(int level) => 5.0 + level * 1.5;

  @override
  double get projectileSpeed => 4.5;
  @override
  String get projectilePath => "weapon/chevron.png";
  @override
  double get projectileSizeX => 0.5;
  @override
  double get projectileSizeY => 0.5;
  @override
  int projectileColumns(level) => 1;
  @override
  int projectileRows(level) => 6;
  @override
  bool get projectLoop => false;
  @override
  String get explosionImage => "weapon/auto_explosion.png";
  @override
  int get explosionColumns => 1;
  @override
  int get explosionRows => 1;
  @override
  double get explosionSizeX => 0.9;
  @override
  double get explosionSizeY => 0.9;

  @override
  Set<Ability> abilities(int level, GemComponent caster) {
    final a = {Ottoman(level: level, caster: caster)};
    for (final ab in a) {
      ab.gemType = gemType;
      ab.buff?.gemType = gemType;
    }
    return a;
  }
}

// Ottoman: every attack also collects tribute — capital per enemy currently
// inside the empire's reach. They pay whether you kill them or not.
class Ottoman extends Ability {
  Ottoman({required super.caster, required super.level});

  static const tributePerEnemy = [0.05, 0.07, 0.09, 0.11, 0.13, 0.15];

  @override
  GameComponent? onEnemyAttack(GemComponent gem, EnemyComponent primaryTarget,
      Set<GameComponent> targets) {
    gem.gameRef.gameStats.capital +=
        tributePerEnemy.getByLevel(level) * targets.length;
    return null;
  }

  @override
  String name = "Ottoman";

  @override
  String description =
      "All who pass through the empire pay tribute — capital collected per "
      "enemy in range, on every attack.";

  @override
  String get subDescription =>
      "+${tributePerEnemy.join("/")} capital per enemy in range per attack.";

  @override
  IconData icon = FontAwesomeIcons.crown.data;

  @override
  CityType gemType = CityType.MENA;
}
