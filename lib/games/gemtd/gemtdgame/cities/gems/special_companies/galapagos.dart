import 'package:flame/components.dart';
import 'package:political_think/games/gemtd/gemtdgame/ability/ability.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gem_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/weapon_settings.dart';
import 'package:political_think/games/gemtd/gemtdgame/game/game_constants.dart';

// South America special — Forced Evolution: each Galápagos copies a random
// tower's entire attack profile + abilities (chosen on construction).
final galapagos_recipe = (cities: ["Lima", "Nairobi", "Jakarta"], gem: Galapagos());

class Galapagos extends GemComponent {
  Galapagos({Vector2? position}) : super(position: position);

  @override
  GemAttributes settings = GalapagosSettings();

  @override
  get currentImagePath => "flags/${countryCodes.first.toLowerCase()}.png";

  @override
  int get level => 6;
}

class GalapagosSettings extends GemAttributes {
  final GemComponent _base = GameConstants.randomGem()..level = 6;

  @override
  late CityType gemType = _base.settings.gemType;

  @override
  List<String> names = ["Galapagos"];

  @override
  String name(int level) => names[0];

  @override
  List<String> countryCodes(int level) => ["EC"];

  @override
  double baseAttackSpeed(int level) => _base.settings.baseAttackSpeed(level);
  @override
  double baseRange(int level) => _base.settings.baseRange(level);
  @override
  double baseDamage(int level) => _base.settings.baseDamage(level);
  @override
  bool isAura(int level) => _base.settings.isAura(level);
  @override
  bool auraRing(int level) => _base.settings.auraRing(level);
  @override
  double get projectileSpeed => _base.settings.projectileSpeed;
  @override
  String get projectilePath => _base.settings.projectilePath;
  @override
  double get projectileSizeX => _base.settings.projectileSizeX;
  @override
  double get projectileSizeY => _base.settings.projectileSizeY;
  @override
  double get projectileStepTime => _base.settings.projectileStepTime;
  @override
  int projectileColumns(level) => _base.settings.projectileColumns(level);
  @override
  int projectileRows(level) => _base.settings.projectileRows(level);
  @override
  bool get projectLoop => _base.settings.projectLoop;
  @override
  bool get canHitIntermediateTargets =>
      _base.settings.canHitIntermediateTargets;
  @override
  bool get aoe => _base.settings.aoe;
  @override
  String get auraPath => _base.settings.auraPath;
  @override
  int auraColumns(int level) => _base.settings.auraColumns(level);
  @override
  int auraRows(int level) => _base.settings.auraRows(level);
  @override
  double get auraScale => _base.settings.auraScale;
  @override
  double get auraStepTime => _base.settings.auraStepTime;
  @override
  String get explosionImage => _base.settings.explosionImage;
  @override
  int get explosionColumns => _base.settings.explosionColumns;
  @override
  int get explosionRows => _base.settings.explosionRows;
  @override
  double get explosionStepTime => _base.settings.explosionStepTime;
  @override
  double get explosionSizeX => _base.settings.explosionSizeX;
  @override
  double get explosionSizeY => _base.settings.explosionSizeY;

  @override
  Set<Ability> abilities(int level, GemComponent caster) =>
      _base.settings.abilities(level, caster);
}
