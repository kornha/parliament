import 'dart:async';
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

part 'africa_abilities.dart';
part 'africa_cities.dart';

class Africa extends GemComponent {
  Africa({super.position});

  @override
  GemAttributes get settings => AfricaSettings(
      cityConfig: africa_cities.getCityConfigByLevelOrLast(level));

  @override
  get currentImagePath => "flags/${countryCodes.first.toLowerCase()}.png";
}

class AfricaSettings extends GemAttributes {
  AfricaSettings({required this.cityConfig});

  final CityConfig cityConfig;

  @override
  CityType gemType = CityType.AFRICA;

  @override
  late List<String> names = [...africa_cities.map((e) => e.city)];

  @override
  List<String> countryCodes(int level) => [cityConfig.countryCode];

  // DR Congo (Cobalt) is a no-attack electrocution aura.
  @override
  bool auraRing(int level) => cityConfig == drCongo;

  // Nigeria (Afrobeat) fires invisible, fast, frequent, low-damage shots.
  // Everyone else fires a green tracer (E.Europe-style bullet, kit green).
  @override
  String get projectilePath => cityConfig == nigeria ?
      "weapon/empty_bullet.png" : "weapon/ie_green_bullet.png";

  // Kenya's Stampede and Ghana's Gold Road pierce a column of enemies.
  @override
  bool get canHitIntermediateTargets =>
      cityConfig == kenya || cityConfig == ghana;

  @override
  int projectileColumns(level) => 1;

  // Single-frame tracer (the old chevron sheet had 6 rows).
  @override
  int projectileRows(level) => 1;

  @override
  double get projectileSizeX => 0.22;

  @override
  double get projectileSizeY => 0.5;

  @override
  bool get projectLoop => false;

  @override
  double get projectileSpeed => switch (cityConfig) {
        nigeria => 9.0,
        kenya => 6.0,
        _ => 4.5,
      };

  @override
  String get explosionImage =>
      cityConfig == nigeria ? "weapon/coinbase_explosion.png" : "weapon/auto_explosion.png";

  @override
  int get explosionColumns => cityConfig == nigeria ? 6 : 1;

  @override
  int get explosionRows => 1;

  @override
  double get explosionSizeX => 0.9;

  @override
  double get explosionSizeY => 0.9;

  @override
  double baseRange(int level) => switch (cityConfig) {
        kenya => 4.0, // long lane for the charge
        drCongo => 2.5, // electrocute aura
        ethiopia => 3.0, // coffee range
        _ => 3.0, // nigeria / ghana / south africa
      };

  @override
  double baseAttackSpeed(int level) => switch (cityConfig) {
        nigeria => 3.5, // machine-gun
        kenya => 0.4, // slow heavy charge
        drCongo => 0.0, // aura, no attack
        ethiopia => 1.2, // steady coffee shots (before the burst/crash)
        _ => 1.0, // ghana / south africa
      };

  @override
  double baseDamage(int level) => switch (cityConfig) {
        nigeria => 1.0 + level * 0.35, // low (machine-gun)
        kenya => 6.5 + level * 3.0, // heavy charge
        drCongo => 0.0, // damage comes from the Cobalt aura buff
        ethiopia => 2.5 + level * 0.9, // light hit; the burst/crash does the rest
        southAfrica => 2.0, // the bite (% current HP) is the real damage
        _ => 3.5 + level * 1.4, // ghana
      };

  @override
  Set<Ability> abilities(int level, covariant Africa caster) {
    final abilities = {...africa_abilities(this, level, caster, cityConfig)};
    abilities.forEach((a) {
      a.gemType = gemType;
      a.buff?.gemType = gemType;
    });
    return abilities;
  }
}
