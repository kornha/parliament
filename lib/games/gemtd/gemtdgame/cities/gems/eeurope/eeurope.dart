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

part 'eeurope_abilities.dart';
part 'eeurope_cities.dart';

class EEurope extends GemComponent {
  EEurope({super.position});

  @override
  GemAttributes get settings => EEuropeSettings(
      cityConfig: eeurope_cities.getCityConfigByLevelOrLast(level));

  @override
  get currentImagePath => "flags/${countryCodes.first.toLowerCase()}.png";
}

class EEuropeSettings extends GemAttributes {
  EEuropeSettings({required this.cityConfig});

  final CityConfig cityConfig;

  @override
  CityType gemType = CityType.EEUROPE;

  @override
  late List<String> names = [...eeurope_cities.map((e) => e.city)];

  @override
  List<String> countryCodes(int level) => [cityConfig.countryCode];

  @override
  double baseRange(int level) => 2.25 + level * 0.25;

  @override
  double baseAttackSpeed(int level) => level * 0.7 + 2.0;

  @override
  double baseDamage(int level) => level * 0.225 + 0.625;

  // Bullet/explosion type swapped with W. Europe (spine swap): tech bullet +
  // big tech explosion.
  @override
  double get projectileSpeed => 4.5;

  @override
  bool get projectLoop => true;

  @override
  int projectileColumns(level) => 1;

  @override
  int projectileRows(level) => 1;

  @override
  String get projectilePath => "weapon/tech_bullet.png";

  @override
  double get projectileSizeX => 0.2;

  @override
  double get projectileSizeY => 0.48;

  @override
  int get explosionColumns => 1;

  @override
  int get explosionRows => 1;

  @override
  double get explosionSizeX => 1.6;

  @override
  double get explosionSizeY => 1.6;

  @override
  double get explosionStepTime => 0.04;

  @override
  String get explosionImage => "weapon/tech_explosion.png";

  @override
  Set<Ability> abilities(int level, covariant EEurope caster) {
    final abilities = {...eeurope_abilities(this, level, caster, cityConfig)};
    abilities.forEach((a) {
      a.gemType = gemType;
      a.buff?.gemType = gemType;
    });
    return abilities;
  }
}
