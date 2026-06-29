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

part 'namerica_abilities.dart';
part 'namerica_cities.dart';

class NAmerica extends GemComponent {
  NAmerica({Vector2? position, bool hidden = false})
      : super(position: position, hideSprite: hidden);

  @override
  GemAttributes get settings => NAmericaSettings(
      cityConfig: namerica_cities.getCityConfigByLevelOrLast(level));

  @override
  get currentImagePath => "flags/${countryCodes.first.toLowerCase()}.png";

  @override
  Future<void>? onLoad() async {
    await super.onLoad();
  }
}

class NAmericaSettings extends GemAttributes {
  NAmericaSettings({required this.cityConfig});

  final CityConfig cityConfig;

  @override
  CityType gemType = CityType.NAMERICA;

  @override
  late List<String> names = [...namerica_cities.map((e) => e.city)];

  @override
  List<String> countryCodes(int level) => [cityConfig.countryCode];

  // USA's Deep State fires invisible shots that detonate in a bomb burst.
  @override
  String get projectilePath => cityConfig == usa
      ? "weapon/empty_bullet.png"
      : "weapon/finance_bullet.png";

  @override
  double get projectileSpeed => cityConfig == usa ? 9.0 : 4.0;

  @override
  bool get projectLoop => cityConfig != usa;

  @override
  int projectileRows(int level) => 1;

  @override
  int projectileColumns(int level) => 1;

  @override
  String get explosionImage =>
      cityConfig == usa ? "weapon/coinbase_explosion.png" : "weapon/explosion2.png";

  @override
  int get explosionColumns => 6;

  @override
  double get explosionSizeX => cityConfig == usa ? 1.2 : 1.0;

  @override
  double get explosionSizeY => cityConfig == usa ? 1.2 : 1.0;

  // Cuba (Viva la Revolución) trades raw damage for its bouncing volley.
  @override
  double baseDamage(int level) {
    final base = 3.2 + level * 1.85;
    return cityConfig == cuba ? base * 0.45 : base;
  }

  @override
  double baseRange(int level) => 3.0;

  @override
  Set<Ability> abilities(int level, covariant NAmerica caster) {
    final abilities = {...namerica_abilities(this, level, caster, cityConfig)};
    for (final a in abilities) {
      a.gemType = gemType;
      a.buff?.gemType = gemType;
    }
    return abilities;
  }
}
