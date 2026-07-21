import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:political_think/games/gemtd/gemtdgame/ability/ability.dart';
import 'package:political_think/games/gemtd/gemtdgame/ability/buff.dart' as bf;
import 'package:political_think/games/gemtd/gemtdgame/cities/gem_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gems/asean/asean.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/weapon_settings.dart';

// ASEAN special — Always Be Burma to Me: time stands still. Debuffs on
// enemies in its range never tick down until they escape.
// Recipe: Cambodia + Venezuela + Lebanon (collapsed states build the junta).
class Myanmar extends GemComponent {
  Myanmar({Vector2? position}) : super(position: position);

  @override
  GemAttributes settings = MyanmarSettings();

  @override
  get currentImagePath => "flags/${countryCodes.first.toLowerCase()}.png";

  @override
  int get level => 6;
}

class MyanmarSettings extends GemAttributes {
  @override
  CityType gemType = CityType.ASEAN;

  // Level 4 base (Indonesia) — a plain ASEAN attacker; level 5 is the
  // Malaysia aura and level 6 the Thailand hidden-bullet special.
  final _base = Asean()..level = 4;

  @override
  List<String> names = ["Myanmar"];

  @override
  String name(int level) => names[0];

  @override
  List<String> countryCodes(int level) => ["MM"];

  @override
  double baseAttackSpeed(int level) => _base.settings.baseAttackSpeed(4);
  @override
  double baseRange(int level) => _base.settings.baseRange(4);
  @override
  double baseDamage(int level) => _base.settings.baseDamage(4);
  @override
  double get projectileSpeed => _base.settings.projectileSpeed;
  @override
  String get projectilePath => _base.settings.projectilePath;
  @override
  double get projectileSizeX => _base.settings.projectileSizeX;
  @override
  double get projectileSizeY => _base.settings.projectileSizeY;
  @override
  int projectileColumns(level) => _base.settings.projectileColumns(4);
  @override
  int projectileRows(level) => _base.settings.projectileRows(4);
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
    final a = {AlwaysBurma(level: level, caster: caster)};
    for (final ab in a) {
      ab.gemType = gemType;
      ab.buff?.gemType = gemType;
    }
    return a;
  }
}

// Always Be Burma to Me: every attack marks all enemies in range as
// Timeless — their debuffs stop expiring (see StatusManager.tickEnemy).
// Stuns stay stunned, burns keep burning, slows never fade — until they
// leave the aura and the clock restarts.
class AlwaysBurma extends Ability {
  AlwaysBurma({required super.caster, required super.level});

  @override
  bool get enemiesAura => true;

  @override
  bf.Buff? get buff => bf.TimelessBuff(caster: caster, level: level);

  @override
  String name = "Always Be Burma to Me";

  @override
  String description =
      "Time stands still: debuffs on enemies in range never wear off until "
      "they escape.";

  @override
  String get subDescription =>
      "Enemies in range keep all debuffs at full duration.";

  @override
  IconData icon = FontAwesomeIcons.hourglassHalf.data;

  @override
  CityType gemType = CityType.ASEAN;
}
