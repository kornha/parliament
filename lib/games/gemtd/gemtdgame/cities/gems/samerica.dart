import 'package:flame/components.dart';
import 'package:political_think/games/gemtd/common/extensions.dart';
import 'package:political_think/games/gemtd/gemtdgame/ability/ability.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gem_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/weapon_settings.dart';

class SAmerica extends GemComponent {
  SAmerica({Vector2? position, bool hidden = false})
      : super(position: position, hideSprite: hidden);

  @override
  GemAttributes settings = SAmericaSettings();

  @override
  get currentImagePath => "city/${name.toLowerCase()}.png";

  @override
  Future<void>? onLoad() async {
    await super.onLoad();
  }
}

class SAmericaSettings extends GemAttributes {
  @override
  CityType gemType = CityType.SAMERICA;

  @override
  List<String> names = [
    "Lima",
    "Medellin",
    "Caracas",
    "Rio de Janeiro",
    "Buenos Aires",
    "Sao Paulo",
  ];

  @override
  List<String> countryCodes(int level) {
    switch (level) {
      case 1:
        return ["PE"];
      case 2:
        return ["CO"];
      case 3:
        return ["VE"];
      case 4:
        return ["BR"];
      case 5:
        return ["AR"];
      default:
        return ["BR"];
    }
  }

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
    return attackRange.getByLevel(level);
  }

  final attackSpeed = [0.4, 0.5, 0.6, 0.7, 0.8, 0.9];
  @override
  double baseAttackSpeed(int level) {
    return attackSpeed.getByLevel(level);
  }

  @override
  double baseDamage(int level) => 1.75 + level * 0.8;

  // Spine: Burn (DoT) shared. Lima(Burn only) -> Medellín(Cartel) ->
  // Caracas(Crude/Oiled) -> Rio(Redeemer) -> Buenos Aires(Tango) ->
  // São Paulo(Inferno — burn aura, cannot attack).
  @override
  Set<Ability> abilities(int level, GemComponent caster) {
    switch (level) {
      case 1:
        return {
          Burn(level: level, caster: caster),
        };
      case 2:
        return {
          Burn(level: level, caster: caster),
          Cartel(level: level, caster: caster),
        };
      case 3:
        return {
          Burn(level: level, caster: caster),
          Crude(level: level, caster: caster),
        };
      case 4:
        return {
          Burn(level: level, caster: caster),
          Redeemer(level: level, caster: caster),
        };
      case 5:
        return {
          Burn(level: level, caster: caster),
          Tango(level: level, caster: caster),
        };
      default:
        return {
          Inferno(level: level, caster: caster),
        };
    }
  }
}
