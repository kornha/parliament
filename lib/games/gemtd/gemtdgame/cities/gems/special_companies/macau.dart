import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:political_think/games/gemtd/common/extensions.dart';
import 'package:political_think/games/gemtd/gemtdgame/ability/ability.dart';
import 'package:political_think/games/gemtd/gemtdgame/ability/buff.dart' as bf;
import 'package:political_think/games/gemtd/gemtdgame/cities/gem_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gems/easia/easia.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/weapon_settings.dart';

// E. Asia special — Casino: every hit spins the wheel for a random stun
// (0 up to ~2s). Mostly nothing, sometimes jackpot.
// Recipe: Hong Kong + Portugal + Thailand.
class Macau extends GemComponent {
  Macau({Vector2? position}) : super(position: position);

  @override
  GemAttributes settings = MacauSettings();

  @override
  get currentImagePath => "flags/${countryCodes.first.toLowerCase()}.png";

  @override
  int get level => 6;
}

class MacauSettings extends GemAttributes {
  @override
  CityType gemType = CityType.EASIA;

  final _base = EAsia()..level = 6;

  @override
  List<String> names = ["Macau"];

  @override
  String name(int level) => names[0];

  @override
  List<String> countryCodes(int level) => ["MO"];

  // Faster spins than the stately E. Asia base — more rolls of the wheel.
  @override
  double baseAttackSpeed(int level) => 1.0;
  @override
  double baseRange(int level) => _base.settings.baseRange(level);
  @override
  double baseDamage(int level) => _base.settings.baseDamage(level) * 0.6;
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
    final a = {Casino(level: level, caster: caster)};
    for (final ab in a) {
      ab.gemType = gemType;
      ab.buff?.gemType = gemType;
    }
    return a;
  }
}

// Casino: every hit stuns for a RANDOM duration — 0 up to the level's
// ceiling. The house always wins eventually.
class Casino extends Ability {
  Casino({required super.caster, required super.level});

  static const maxStunPerLevel = [1.2, 1.4, 1.6, 1.8, 2.0, 2.2];

  @override
  bool get worksOnEnemies => true;

  @override
  bf.Buff? get buff => bf.Stun(
        caster: caster,
        level: level,
        overrideDuration:
            Random().nextDouble() * maxStunPerLevel.getByLevel(level),
      )
        ..name = name
        ..icon = icon
        ..gemType = gemType;

  @override
  String name = "Casino";

  @override
  String description =
      "Every hit spins the wheel: a random stun, from nothing to a jackpot.";

  @override
  String get subDescription =>
      "Stuns 0 to ${maxStunPerLevel.join("/")}s, rolled per hit.";

  @override
  IconData icon = FontAwesomeIcons.dice.data;

  @override
  CityType gemType = CityType.EASIA;
}
