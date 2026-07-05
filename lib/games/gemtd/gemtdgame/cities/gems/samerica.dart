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

import '../city_config.dart';

part 'samerica_abilities.dart';
part 'samerica_cities.dart';

class SAmerica extends GemComponent {
  SAmerica({Vector2? position, bool hidden = false})
      : super(position: position, hideSprite: hidden);

  @override
  GemAttributes settings = SAmericaSettings();

  @override
  get currentImagePath => "flags/${countryCodes.first.toLowerCase()}.png";

  @override
  Future<void>? onLoad() async {
    await super.onLoad();
  }
}

class SAmericaSettings extends GemAttributes {
  SAmericaSettings({CityConfig? cityConfig})
      : cityConfig =
            cityConfig ?? samerica_cities.getCityConfigByLevelOrLast(1);

  CityConfig cityConfig;

  @override
  CityType gemType = CityType.SAMERICA;

  @override
  late List<String> names = [...samerica_cities.map((e) => e.city)];

  @override
  List<String> countryCodes(int level) =>
      [samerica_cities.getCityConfigByLevelOrLast(level).countryCode];

  @override
  double get projectileSpeed => 2.75;

  @override
  double get projectileSizeX => 0.30;

  @override
  double get projectileSizeY => 0.7;

  @override
  String get projectilePath => "weapon/Bullet2.png";

  @override
  String get explosionImage => "weapon/fashion_explosion.png";

  @override
  double get explosionStepTime => 0.012;

  @override
  double get explosionSizeX => 1.85;

  @override
  double get explosionSizeY => 1.85;

  @override
  int get explosionColumns => 5;

  @override
  int get explosionRows => 5;

  @override
  bool get aoe => true;

  final attackRange = [2.5, 2.6, 2.7, 2.8, 2.9];
  @override
  double baseRange(int level) {
    // Chile (Inferno) is a tight burn aura — far shorter than the attackers.
    if (level == chile.level) return 1.4;
    return attackRange.getByLevel(level);
  }

  final attackSpeed = [0.4, 0.5, 0.6, 0.7, 0.8, 0.9];
  @override
  double baseAttackSpeed(int level) {
    return attackSpeed.getByLevel(level);
  }

  @override
  double baseDamage(int level) => 1.75 + level * 0.8;

  // Chile (Inferno) is a no-attack burn aura — show the pulsing ring.
  @override
  bool auraRing(int level) => level == chile.level;

  @override
  Set<Ability> abilities(int level, GemComponent caster) {
    final config = samerica_cities.getCityConfigByLevelOrLast(level);
    final abilities = {...samerica_abilities(this, level, caster, config)};
    abilities.forEach((a) {
      a.gemType = gemType;
      a.buff?.gemType = gemType;
    });
    return abilities;
  }
}
