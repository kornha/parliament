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

// Eastern Europe special — carries the region's Oligarchy spine (compounding
// attack speed) plus Checkered Past, its damage twin: consecutive hits on the
// same enemy compound BOTH attack speed and damage.
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
    final a = {
      Oligarchy(level: level, caster: caster),
      CheckeredPast(level: level, caster: caster),
    };
    for (final ab in a) {
      ab.gemType = gemType;
      ab.buff?.gemType = gemType;
    }
    return a;
  }
}

// Checkered Past: the damage twin of Oligarchy — each consecutive hit on the
// same enemy compounds attack DAMAGE (resets on target switch, caps at 50 like
// Oligarchy). Damage is the one compounding type the game didn't have.
class CheckeredPast extends Ability {
  CheckeredPast({required super.caster, required super.level});

  static const _max = 50; // same stack cap as Oligarchy
  static const increasePerLevel = [0.03, 0.04, 0.05, 0.06, 0.08, 0.10];

  int count = 0;

  @override
  GameComponent? onEnemyAttack(GemComponent gem, EnemyComponent primaryTarget,
      Set<GameComponent> targets) {
    // Compounds per consecutive hit on the same enemy; resets when the target
    // changes — exactly like Oligarchy, but stacking damage instead of speed.
    if (caster.lastEnemy == primaryTarget) {
      if (count < _max) count++;
    } else {
      count = 0;
    }
    // Re-apply the compounded damage multiplier each attack (a CriticalStrike
    // with a growing multiplier, refreshed like Capitalism's).
    final cs = bf.CriticalStrike(
      caster: caster,
      level: level,
      overrideDamageMultiplier: 1 + count * increasePerLevel.getByLevel(level),
    )
      ..name = name
      ..icon = icon
      ..gemType = gemType;
    if (gem.buffs.contains(cs)) {
      for (final b in gem.buffs) {
        if (b == cs) {
          b.duration = cs.duration;
          (b as bf.CriticalStrike).overrideDamageMultiplier =
              cs.overrideDamageMultiplier;
        }
      }
    } else {
      gem.buffs.add(cs);
    }
    return null;
  }

  @override
  String name = "Checkered Past";

  @override
  String description =
      "Each consecutive hit on the same enemy compounds attack damage.";

  @override
  String get subDescription =>
      "+${increasePerLevel.map((e) => "${(e * 100).toStringAsFixed(0)}%").join("/")} damage per hit.";

  @override
  IconData icon = FontAwesomeIcons.chessBoard.data;

  @override
  CityType gemType = CityType.EEUROPE;
}
