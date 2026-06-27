import 'dart:math';

import 'package:flame/components.dart';
import 'package:political_think/games/gemtd/gemtdgame/ability/ability.dart';
import 'package:political_think/games/gemtd/gemtdgame/base/game_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/game/game_constants.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/barrel_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/bullet_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gem_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gems/asean/asean.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gems/easia/easia.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/weapon_settings.dart';

class NFL extends GemComponent {
  NFL({Vector2? position}) : super(position: position);

  @override
  GemAttributes settings = NFLSettings();

  @override
  int get level => 3;

  @override
  Future<void>? onLoad() async {
    await super.onLoad();
  }
}

class NFLSettings extends GemAttributes {
  @override
  List<String> names = ["NFL"];

  @override
  String name(int level) => names[0];

  @override
  CityType gemType = CityType.ASEAN;

  final _base = Asean()..level = 3;
  final _baseProjectile = EAsia()..level = 3;

  @override
  double baseAttackSpeed(int level) => 3;

  @override
  double baseRange(int level) => _base.settings.baseRange(level);

  @override
  double baseDamage(int level) => _base.settings.baseDamage(level);

  @override
  double get projectileSpeed => _baseProjectile.settings.projectileSpeed;

  @override
  String get projectilePath => "weapon/stun.png";

  @override
  double get projectileSizeX => _baseProjectile.settings.projectileSizeX;

  @override
  double get projectileSizeY => _baseProjectile.settings.projectileSizeY;

  @override
  double get explosionSizeX => _baseProjectile.settings.explosionSizeX;

  @override
  double get explosionSizeY => _baseProjectile.settings.explosionSizeY;

  @override
  bool get aoe => false;

  @override
  int projectileColumns(level) => _base.settings.projectileColumns(level);

  @override
  int projectileRows(level) => _base.settings.projectileRows(level);

  @override
  bool get projectLoop => _baseProjectile.settings.projectLoop;

  @override
  double get projectileStepTime => _baseProjectile.settings.projectileStepTime;

  @override
  String get explosionImage => "weapon/nfl_explosion.png";

  @override
  int get explosionColumns => _baseProjectile.settings.explosionColumns;

  @override
  int get explosionRows => _baseProjectile.settings.explosionRows;

  @override
  double get explosionStepTime => _baseProjectile.settings.explosionStepTime;

  @override
  Set<Ability> abilities(int level, GemComponent caster) =>
      {ManufacturedTechnology(caster: caster, level: level)};
}
