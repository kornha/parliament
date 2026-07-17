import 'dart:math';

import 'package:flame/components.dart';
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

part 'easia_abilities.dart';
part 'easia_cities.dart';

class EAsia extends GemComponent {
  EAsia({Vector2? position}) : super(position: position);

  @override
  get currentImagePath => "flags/${countryCodes.first.toLowerCase()}.png";

  @override
  GemAttributes get settings =>
      EAsiaSettings(cityConfig: easia_cities.getCityConfigByLevelOrLast(level));

  @override
  Future<void>? onLoad() async {
    await super.onLoad();
  }
}

class EAsiaSettings extends GemAttributes {
  EAsiaSettings({CityConfig? cityConfig})
      : cityConfig = cityConfig ?? easia_cities.first;

  final CityConfig cityConfig;

  @override
  CityType gemType = CityType.EASIA;

  @override
  late List<String> names = [...easia_cities.map((e) => e.city)];

  @override
  List<String> countryCodes(int level) => [cityConfig.countryCode];

  @override
  double baseAttackSpeed(int level) => 0.4 + level * 0.05;

  @override
  bool get canHitIntermediateTargets => false;

  @override
  double get projectileSpeed => 5;

  final List<double> attackRange = [3.3, 3.4, 3.5, 3.6, 3.7, 3.8];
  @override
  double baseRange(int level) => attackRange.getByLevel(level);

  @override
  double baseDamage(int level) => 7.0 + level * 1.2;

  @override
  String get projectilePath => "projectile/easia_projectile.png";

  @override
  double get projectileSizeX => 0.8;

  @override
  double get projectileSizeY => 0.8;

  @override
  int projectileColumns(int level) => 1;

  @override
  int projectileRows(int level) => 5;

  @override
  bool get projectLoop => false;

  @override
  double get projectileStepTime => 0.03;

  @override
  String get explosionImage => "explosion/easia_explosion.png";

  @override
  int get explosionColumns => 6;

  @override
  int get explosionRows => 1;

  @override
  double get explosionSizeX => 1.2;

  @override
  double get explosionSizeY => 1.2;

  @override
  double get explosionStepTime => 0.06;

  @override
  Set<Ability> abilities(int level, covariant EAsia caster) {
    final abilities = {...easia_abilities(this, level, caster, cityConfig)};
    abilities.forEach((a) {
      a.gemType = gemType;
      a.buff?.gemType = gemType;
    });
    return abilities;
  }
}
