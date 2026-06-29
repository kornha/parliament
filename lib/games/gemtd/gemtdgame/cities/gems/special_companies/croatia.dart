import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:political_think/games/gemtd/common/extensions.dart';
import 'package:political_think/games/gemtd/gemtdgame/ability/ability.dart';
import 'package:political_think/games/gemtd/gemtdgame/ability/buff.dart' as bf;
import 'package:political_think/games/gemtd/gemtdgame/base/game_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gem_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gems/eeurope/eeurope.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/weapon_settings.dart';
import 'package:political_think/games/gemtd/gemtdgame/enemy/enemy_component.dart';

// Eastern Europe special — Checkered Past: permanently gains attack speed for
// every kill (soft-capped). A relentless, ever-accelerating snowball.
class Croatia extends GemComponent {
  Croatia({Vector2? position}) : super(position: position);

  @override
  GemAttributes settings = CroatiaSettings();

  @override
  get currentImagePath => "flags/${countryCodes.first.toLowerCase()}.png";

  @override
  int get level => 6;
}

class CroatiaSettings extends GemAttributes {
  @override
  CityType gemType = CityType.EEUROPE;

  final _base = EEurope()..level = 6;

  @override
  List<String> names = ["Croatia"];

  @override
  String name(int level) => names[0];

  @override
  List<String> countryCodes(int level) => ["HR"];

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
    final a = {CheckeredPast(level: level, caster: caster)};
    for (final ab in a) {
      ab.gemType = gemType;
      ab.buff?.gemType = gemType;
    }
    return a;
  }
}

// Checkered Past: a permanent attack-speed snowball — every kill makes Croatia
// fire faster, forever, up to a soft cap.
class CheckeredPast extends Ability {
  CheckeredPast({required super.caster, required super.level});

  static const incPerKill = [0.04, 0.05, 0.06, 0.07, 0.08, 0.10];
  static const _softCapStacks = 25;

  int kills = 0;
  final Set<EnemyComponent> _counted = {};

  @override
  GameComponent? onEnemyAttack(GemComponent gem, EnemyComponent primaryTarget,
      Set<GameComponent> targets) {
    // The previous target dying counts as a kill (lastEnemy is set after this).
    final last = caster.lastEnemy;
    if (last != null && last.dead && !_counted.contains(last)) {
      _counted.add(last);
      if (kills < _softCapStacks) kills++;
    }
    gem.buffs.add(bf.AttackSpeedMultiple(
      caster: caster,
      level: level,
      overrideDurationType: bf.DurationType.ATTACK,
      overrideMultiplier: 1 + kills * incPerKill.getByLevel(level),
    ));
    return null;
  }

  @override
  String name = "Checkered Past";

  @override
  String description =
      "Permanently gains attack speed for every kill (up to a soft cap).";

  @override
  String get subDescription =>
      "+${incPerKill.map((e) => "${(e * 100).toStringAsFixed(0)}%").join("/")} attack speed per kill.";

  @override
  IconData icon = FontAwesomeIcons.chessBoard.data;

  @override
  CityType gemType = CityType.EEUROPE;
}
