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

part 'weurope_abilities.dart';
part 'weurope_cities.dart';

class WEurope extends GemComponent {
  WEurope({super.position});

  @override
  GemAttributes get settings => WEuropeSettings(
      cityConfig: weurope_cities.getCityConfigByLevelOrLast(level));

  @override
  get currentImagePath => "city/${name.toLowerCase()}.png";
}

class WEuropeSettings extends GemAttributes {
  WEuropeSettings({required this.cityConfig});

  final CityConfig cityConfig;

  @override
  CityType gemType = CityType.WEUROPE;

  @override
  late List<String> names = [...weurope_cities.map((e) => e.city)];

  @override
  List<String> countryCodes(int level) => [cityConfig.countryCode];

  // Bullet/explosion type swapped with E. Europe (spine swap): chevron +
  // auto explosion across all cities.
  @override
  String get projectilePath => "weapon/chevron.png";

  @override
  bool get projectLoop => false;

  @override
  String get explosionImage => "weapon/auto_explosion.png";

  @override
  double baseDamage(int level) => 0.56 + level * 0.3;

  // Brussels is the slow board-wide bureaucrat; everyone else fires fast.
  @override
  double baseAttackSpeed(int level) =>
      cityConfig == brussels ? 0.35 : 2.85 + level * 0.28;

  // Brussels & London reach the entire board (hit-all); the rest are local.
  @override
  double baseRange(int level) =>
      (cityConfig == brussels || cityConfig == london) ? 15.0 : 3.0;

  @override
  double projectileSizeX = 0.5;

  @override
  double projectileSizeY = 0.5;

  @override
  int projectileRows(level) => 6;

  @override
  int projectileColumns(level) => 1;

  @override
  int get explosionColumns => 1;

  @override
  int get explosionRows => 1;

  @override
  double get explosionSizeX => 0.9;

  @override
  double get explosionSizeY => 0.9;

  @override
  double get explosionStepTime => 0.06;

  @override
  bool get canHitIntermediateTargets => false;

  @override
  Set<Ability> abilities(int level, covariant WEurope caster) {
    final abilities = {...weurope_abilities(this, level, caster, cityConfig)};
    abilities.forEach((a) {
      a.gemType = gemType;
      a.buff?.gemType = gemType;
    });
    return abilities;
  }
}
