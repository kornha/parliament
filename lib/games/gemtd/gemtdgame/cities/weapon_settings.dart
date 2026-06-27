import 'package:flame/components.dart';
import 'package:political_think/games/gemtd/common/extensions.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gem_component.dart';

import '../ability/ability.dart';
import '../game/game_constants.dart';

abstract class GemAttributes {
  // name
  abstract List<String> names;
  List<String> countryCodes(int level) => [];
  String name(int level) => names.getByLevel(level);
  abstract CityType gemType;
  Set<Ability> abilities(int level, GemComponent caster) => {};

  //// attack
  double baseDamage(int level) => 1.0 * 1 + level / 5;
  double baseRange(int level) => 0.9 * 1 + level / 10;
  double baseAttackSpeed(int level) => 0.9 * 1 + level / 10;
  bool isAura(int level) => false;

  // DO NOT CHANGE OR CAN CLICK THROUGH!
  // TODO: Stop clickthrough bug with map
  double sizeX = 1;
  double sizeY = 1;

  // aura
  int auraRows(int level) => 1;
  int auraColumns(int level) => 1;
  String auraPath = "weapon/Bullet2.png";
  double auraStepTime = 0.1;
  double auraScale = 1;

  //projectile
  int projectileRows(int level) => 1;
  int projectileColumns(int level) => 1;
  String projectilePath = "weapon/Bullet2.png";
  double projectileStepTime = 0.1;
  double projectileSizeX = 0.15;
  double projectileSizeY = 0.7;
  double projectileSpeed = 4;
  bool projectLoop = true;
  bool canHitIntermediateTargets = true;

  // explosion, not used in Aura
  final double explosionStepTime = 0.06;
  final String explosionImage = "weapon/explosion2.png";
  final int explosionColumns = 6;
  final int explosionRows = 1;
  final double explosionSizeX = 1;
  final double explosionSizeY = 1;
  final bool aoe = false;

  late Vector2 size = gameSettings.scaleOnMapTile(Vector2(sizeX, sizeY));
  late Vector2 bulletSize =
      gameSettings.scaleOnMapTile(Vector2(projectileSizeX, projectileSizeY));
  late Vector2 explosionSize =
      gameSettings.scaleOnMapTile(Vector2(explosionSizeX, explosionSizeY));
}
