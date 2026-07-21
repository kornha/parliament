import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:political_think/games/gemtd/common/extensions.dart';
import 'package:political_think/games/gemtd/gemtdgame/ability/ability.dart';
import 'package:political_think/games/gemtd/gemtdgame/ability/buff.dart' as bf;
import 'package:political_think/games/gemtd/gemtdgame/base/game_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gem_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gems/weurope/weurope.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/weapon_settings.dart';
import 'package:political_think/games/gemtd/gemtdgame/enemy/enemy_component.dart';

// W. Europe special — Golden Passport: wealth is power. Monaco's damage
// scales with your TOTAL capital. Recipe: Ireland + Ukraine + UAE (the
// haven, the oligarchs, the refuge).
class Monaco extends GemComponent {
  Monaco({Vector2? position}) : super(position: position);

  @override
  GemAttributes settings = MonacoSettings();

  @override
  get currentImagePath => "flags/${countryCodes.first.toLowerCase()}.png";

  @override
  int get level => 6;
}

class MonacoSettings extends GemAttributes {
  @override
  CityType gemType = CityType.WEUROPE;

  final _base = WEurope()..level = 6;

  @override
  List<String> names = ["Monaco"];

  @override
  String name(int level) => names[0];

  @override
  List<String> countryCodes(int level) => ["MC"];

  @override
  double baseAttackSpeed(int level) => _base.settings.baseAttackSpeed(level);
  @override
  double baseRange(int level) => _base.settings.baseRange(level);
  // Modest base — the passport does the lifting.
  @override
  double baseDamage(int level) => _base.settings.baseDamage(level) * 0.5;
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
    final a = {GoldenPassport(level: level, caster: caster)};
    for (final ab in a) {
      ab.gemType = gemType;
      ab.buff?.gemType = gemType;
    }
    return a;
  }
}

// Golden Passport: damage multiplies with the square root of your total
// capital. Hoard wealth and the oligarchs' harbor becomes your carry.
class GoldenPassport extends Ability {
  GoldenPassport({required super.caster, required super.level});

  static const divisorPerLevel = [14.0, 13.0, 12.0, 11.0, 10.0, 9.0];
  static const maxMultiplier = 8.0;

  @override
  GameComponent? onEnemyAttack(GemComponent gem, EnemyComponent primaryTarget,
      Set<GameComponent> targets) {
    final capital = gem.gameRef.gameStats.capital;
    final mult = min(maxMultiplier,
        1 + sqrt(max(0.0, capital)) / divisorPerLevel.getByLevel(level));
    gem.buffs.add(bf.DamageMultiple(
      caster: caster,
      level: level,
      overrideMultiplier: mult,
    )
      ..name = name
      ..icon = icon
      ..gemType = gemType);
    return null;
  }

  @override
  String name = "Golden Passport";

  @override
  String description =
      "Wealth is power: damage scales with your total capital.";

  @override
  String get subDescription =>
      "Damage x(1 + sqrt(capital)/${divisorPerLevel.join("/")}), "
      "up to ${maxMultiplier.toStringAsFixed(0)}x.";

  @override
  IconData icon = FontAwesomeIcons.passport.data;

  @override
  CityType gemType = CityType.WEUROPE;
}
