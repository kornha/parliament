import 'dart:math';

import 'package:flame/components.dart';
import 'package:political_think/games/gemtd/gemtdgame/ability/ability.dart';
import 'package:political_think/games/gemtd/gemtdgame/base/game_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/game/game_constants.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/barrel_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/bullet_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gem_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gems/easia/easia.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/weapon_settings.dart';

class HardRock extends GemComponent {
  HardRock({Vector2? position}) : super(position: position);

  @override
  GemAttributes settings = HardRockSettings();

  @override
  int get level => 2;

  @override
  Future<void>? onLoad() async {
    await super.onLoad();
  }
}

class HardRockSettings extends GemAttributes {
  @override
  List<String> names = ["Hard Rock"];

  @override
  String name(int level) => names[0];

  @override
  CityType gemType = CityType.EASIA;

  @override
  double baseAttackSpeed(int level) => 0.5;

  @override
  double get projectileSpeed => 5;

  final _settings = EAsiaSettings();

  @override
  double baseRange(int level) => _settings.baseRange(level);

  @override
  double baseDamage(int level) => _settings.baseDamage(level);

  @override
  String get projectilePath => "weapon/stun_hospitality.png";

  @override
  double get projectileSizeX => 0.8;

  @override
  double get projectileSizeY => 0.8;

  @override
  double get explosionSizeX => 1.5;

  @override
  double get explosionSizeY => 1.5;

  @override
  bool get aoe => true;

  @override
  int projectileColumns(level) => 1;

  @override
  int projectileRows(level) => 5;

  @override
  bool get projectLoop => false;

  @override
  double get projectileStepTime => 0.03;

  @override
  String get explosionImage => "weapon/hospitality_explosion.png";

  @override
  int get explosionColumns => 6;

  @override
  int get explosionRows => 1;

  @override
  double get explosionStepTime => 0.06;

  @override
  Set<Ability> abilities(int level, GemComponent caster) => {
        Balance(level: level, caster: caster),
        Allure(level: level, caster: caster),
      };
}
