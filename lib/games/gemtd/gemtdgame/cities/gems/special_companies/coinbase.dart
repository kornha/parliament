import 'dart:math';

import 'package:flame/components.dart';
import 'package:political_think/games/gemtd/gemtdgame/ability/ability.dart';
import 'package:political_think/games/gemtd/gemtdgame/base/game_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/barrel_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/bullet_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gem_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/weapon_settings.dart';

import '../namerica/namerica.dart';

class Coinbase extends GemComponent {
  Coinbase({Vector2? position, bool hidden = false})
      : super(position: position, hideSprite: hidden);

  @override
  GemAttributes settings = CoinbaseSettings();

  @override
  int get level => 3;

  @override
  Future<void>? onLoad() async {
    await super.onLoad();
  }
}

class CoinbaseSettings extends GemAttributes {
  @override
  CityType gemType = CityType.NAMERICA;

  @override
  List<String> names = ["Coinbase"];

  @override
  String name(int level) => names[0];

  final _base = NAmerica()..level = 3;

  @override
  double baseAttackSpeed(int level) => _base.settings.baseAttackSpeed(level);

  @override
  double baseRange(int level) => _base.settings.baseRange(level);

  @override
  double baseDamage(int level) => _base.settings.baseDamage(level);

  @override
  String get projectilePath => "weapon/empty_bullet.png";

  @override
  String get explosionImage => "weapon/coinbase_explosion.png";

  @override
  // TODO: implement explosionColumns
  int get explosionColumns => 5;

  @override
  // TODO: implement explosionStepTime
  double get explosionStepTime => 0.04;

  @override
  bool get canHitIntermediateTargets => false;

  @override
  Set<Ability> abilities(int level, GemComponent caster) => {
        FullMoon(level: level, caster: caster),
        Capitalism(level: level, caster: caster),
      };
}
