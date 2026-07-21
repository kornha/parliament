import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:political_think/games/gemtd/gemtdgame/ability/ability.dart';
import 'package:political_think/games/gemtd/gemtdgame/ability/buff.dart' as bf;
import 'package:political_think/games/gemtd/gemtdgame/cities/gem_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gems/africa/africa.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/weapon_settings.dart';

// Africa special — Move It Move It: the charge-lane attack, but fast.
// Rapid straight piercing shots that plow the whole line.
// Recipe: Ghana + Nigeria + Morocco (the island assembled from its
// continent — with Nollywood in the mix for the movie).
class Madagascar extends GemComponent {
  Madagascar({Vector2? position}) : super(position: position);

  @override
  GemAttributes settings = MadagascarSettings();

  @override
  get currentImagePath => "flags/${countryCodes.first.toLowerCase()}.png";

  @override
  int get level => 6;
}

class MadagascarSettings extends GemAttributes {
  @override
  CityType gemType = CityType.AFRICA;

  // Kenya's charge-lane config is the base: green tracer, pierce line.
  final _base = AfricaSettings(cityConfig: kenya);

  @override
  List<String> names = ["Madagascar"];

  @override
  String name(int level) => names[0];

  @override
  List<String> countryCodes(int level) => ["MG"];

  // Much faster than Kenya's slow heavy charge — King Julien tempo.
  @override
  double baseAttackSpeed(int level) => 1.6;
  @override
  double baseRange(int level) => 4.0;
  @override
  double baseDamage(int level) => 2.5 + level * 1.0;

  @override
  double get projectileSpeed => 8.0;
  @override
  bool get canHitIntermediateTargets => true;
  @override
  bool get homingProjectiles => false;

  @override
  String get projectilePath => _base.projectilePath;
  @override
  double get projectileSizeX => _base.projectileSizeX;
  @override
  double get projectileSizeY => _base.projectileSizeY;
  @override
  int projectileColumns(level) => _base.projectileColumns(level);
  @override
  int projectileRows(level) => _base.projectileRows(level);
  @override
  bool get projectLoop => _base.projectLoop;
  @override
  String get explosionImage => _base.explosionImage;
  @override
  int get explosionColumns => _base.explosionColumns;
  @override
  int get explosionRows => _base.explosionRows;
  @override
  double get explosionSizeX => _base.explosionSizeX;
  @override
  double get explosionSizeY => _base.explosionSizeY;

  @override
  Set<Ability> abilities(int level, GemComponent caster) {
    final a = {MoveItMoveIt(level: level, caster: caster)};
    for (final ab in a) {
      ab.gemType = gemType;
      ab.buff?.gemType = gemType;
    }
    return a;
  }
}

// Move It Move It: shots pierce everything in their lane, at speed.
class MoveItMoveIt extends Ability {
  MoveItMoveIt({required super.caster, required super.level});

  @override
  bool get worksOnEnemies => true;

  @override
  bf.Buff? get buff => bf.Pierce(caster: caster, level: level)
    ..name = name
    ..icon = icon
    ..gemType = gemType;

  @override
  String name = "Move It Move It";

  @override
  String description =
      "Rapid straight-lane charges that pierce every enemy in their path.";

  @override
  String get subDescription =>
      "Fast piercing shots; projectiles never stop at the first target.";

  @override
  IconData icon = FontAwesomeIcons.personRunning.data;

  @override
  CityType gemType = CityType.AFRICA;
}
