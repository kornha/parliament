import 'dart:async' as async;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:political_think/games/gemtd/common/extensions.dart';
import 'package:political_think/games/gemtd/gemtdgame/ability/ability.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gem_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gems/namerica/namerica.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/weapon_settings.dart';
import 'package:political_think/games/gemtd/gemtdgame/enemy/enemy_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/game/game_constants.dart';

// N. America special — Magnetic North: the pole pulls. Periodically drags
// every enemy in range back toward the tower, off their path.
// Recipe: Canada + Mongolia + Chile (Arctic neighbor, coldest capital,
// gateway to the other pole).
class Greenland extends GemComponent {
  Greenland({Vector2? position}) : super(position: position);

  @override
  GemAttributes settings = GreenlandSettings();

  @override
  get currentImagePath => "flags/${countryCodes.first.toLowerCase()}.png";

  @override
  int get level => 6;
}

class GreenlandSettings extends GemAttributes {
  @override
  CityType gemType = CityType.NAMERICA;

  final _base = NAmerica()..level = 6;

  @override
  List<String> names = ["Greenland"];

  @override
  String name(int level) => names[0];

  @override
  List<String> countryCodes(int level) => ["GL"];

  @override
  double baseAttackSpeed(int level) => _base.settings.baseAttackSpeed(level);
  @override
  double baseRange(int level) => _base.settings.baseRange(level);
  @override
  double baseDamage(int level) => _base.settings.baseDamage(level) * 0.8;
  @override
  double get projectileSpeed => _base.settings.projectileSpeed;
  @override
  String get projectilePath => _base.settings.projectilePath;
  @override
  double get projectileSizeX => _base.settings.projectileSizeX;
  @override
  double get projectileSizeY => _base.settings.projectileSizeY;
  @override
  int projectileColumns(level) => _base.settings.projectileColumns(level);
  @override
  int projectileRows(level) => _base.settings.projectileRows(level);
  @override
  bool get projectLoop => _base.settings.projectLoop;
  @override
  String get explosionImage => _base.settings.explosionImage;
  @override
  int get explosionColumns => _base.settings.explosionColumns;
  @override
  int get explosionRows => _base.settings.explosionRows;
  @override
  double get explosionSizeX => _base.settings.explosionSizeX;
  @override
  double get explosionSizeY => _base.settings.explosionSizeY;

  @override
  Set<Ability> abilities(int level, GemComponent caster) {
    final a = {MagneticNorth(level: level, caster: caster)};
    for (final ab in a) {
      ab.gemType = gemType;
      ab.buff?.gemType = gemType;
    }
    return a;
  }
}

// Magnetic North: on a timer, every enemy in range is dragged toward the
// tower and re-paths from wherever it lands — the pole does not ask.
class MagneticNorth extends Ability {
  MagneticNorth({required super.caster, required super.level}) {
    timer = async.Timer.periodic(
        const Duration(milliseconds: 3500), (_) => _pull());
  }

  late final async.Timer timer;

  static const pullTilesPerLevel = [0.8, 0.9, 1.0, 1.1, 1.2, 1.4];

  void _pull() {
    if (!caster.isMounted || caster.isRemoved) return;
    final range = caster.radarRange;
    final pullBase = pullTilesPerLevel.getByLevel(level) *
        gameSettings.mapTileSize.length;
    final enemies = caster.gameRef.gameController.children
        .whereType<EnemyComponent>()
        .where((e) =>
            e.active && e.position.distanceTo(caster.position) <= range)
        .toList();
    for (final e in enemies) {
      final dir = caster.position - e.position;
      final distance = dir.length;
      if (distance == 0) continue;
      dir.normalize();
      // Never drag an enemy past the tower itself.
      final pull = pullBase < distance * 0.8 ? pullBase : distance * 0.8;
      e.position.add(dir * pull);
      e.moveNext();
    }
  }

  @override
  void onGemDestroyed(GemComponent gem) {
    timer.cancel();
    super.onGemDestroyed(gem);
  }

  @override
  void onGemConverted(GemComponent gem) {
    timer.cancel();
    super.onGemConverted(gem);
  }

  @override
  String name = "Magnetic North";

  @override
  String description =
      "The pole pulls: periodically drags every enemy in range back toward "
      "the tower, forcing them to re-walk.";

  @override
  String get subDescription =>
      "Every 3.5s, pulls enemies ${pullTilesPerLevel.join("/")} tiles.";

  @override
  IconData icon = FontAwesomeIcons.magnet.data;

  @override
  CityType gemType = CityType.NAMERICA;
}
