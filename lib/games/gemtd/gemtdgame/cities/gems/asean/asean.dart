import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:political_think/games/gemtd/common/extensions.dart';
import 'package:political_think/games/gemtd/gemtdgame/ability/ability.dart';
import 'package:political_think/games/gemtd/gemtdgame/ability/buff.dart' as bf;
import 'package:political_think/games/gemtd/gemtdgame/cities/gem_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/weapon_settings.dart';

import '../../city_config.dart';
import 'hanoi.dart';

part 'asean_abilities.dart';
part 'asean_cities.dart';

class Asean extends GemComponent {
  Asean({super.position});

  @override
  GemAttributes get settings => level == bangkok.level
      ? BangkokSettings(cityConfig: bangkok)
      : AseanSettings(
          cityConfig: asean_cities.getCityConfigByLevelOrLast(level));

  @override
  get currentImagePath => "city/${name.toLowerCase()}.png";
}

const _isAura = {
  kuala_lumpur,
};

class AseanSettings extends GemAttributes {
  static const attackSpeed = [0.85, 0.90, 0.95, 1.0, 1.05, 1.1];

  AseanSettings({required this.cityConfig});

  final CityConfig cityConfig;

  @override
  CityType gemType = CityType.ASEAN;

  @override
  late List<String> names = [...asean_cities.map((e) => e.city)];

  @override
  List<String> countryCodes(int level) => [
        ...asean_cities.where((e) => e.level == level).map((e) => e.countryCode)
      ];

  @override
  String get auraPath => "projectile/asean_aura.png";

  @override
  int auraColumns(int level) => 4;

  @override
  int auraRows(int level) => 3;

  @override
  double get auraScale => 1.3;

  @override
  double get auraStepTime => 0.085;

  @override
  double get projectileSpeed => 2.95;

  @override
  double get projectileSizeX => 0.2;

  @override
  double get projectileSizeY => 0.5;

  @override
  int projectileColumns(level) => 1;

  @override
  int projectileRows(level) => 1;

  @override
  String get projectilePath => "projectile/asean_projectile.png";

  @override
  String get explosionImage => "explosion/asean_explosion.png";

  @override
  // TODO: implement explosionStepTime
  double get explosionStepTime => 0.05;

  @override
  bool get aoe => true;

  @override
  double get explosionSizeX => 1.8;

  @override
  double get explosionSizeY => 1.8;

  @override
  int get explosionColumns => 6;

  @override
  int get explosionRows => 1;

  @override
  bool isAura(int level) => _isAura.any((e) => e.level == level);

  //standard
  final attackRange = [3.0, 3.2, 3.4, 3.6, 3.8, 4.0];

  //second format
  final attackRange2 = [0.8, 0.9, 1.0, 1.1, 1.2, 1.3];

  @override
  double baseRange(int level) => isAura(level)
      ? attackRange2.getByLevel(level)
      : attackRange.getByLevel(level);

  @override
  double baseAttackSpeed(int level) =>
      attackSpeed.getByLevel(level) * (isAura(level) ? 1.0 : 1.0);

  @override
  double baseDamage(int level) =>
      1.7 + level * 0.5 * (isAura(level) ? 0.45 : 1.0);

  @override
  Set<Ability> abilities(int level, GemComponent caster) {
    final abilities = {...asean_abilities(this, level, caster, cityConfig)};
    abilities.forEach((a) {
      a.gemType = gemType;
      a.buff?.gemType = gemType;
    });
    return abilities;
  }
}

class BangkokSettings extends AseanSettings {
  BangkokSettings({required super.cityConfig});

  @override
  bool get canHitIntermediateTargets => false;

  @override
  String get projectilePath => "weapon/empty_bullet.png";

  @override
  String get explosionImage => "weapon/coinbase_explosion.png";
}
