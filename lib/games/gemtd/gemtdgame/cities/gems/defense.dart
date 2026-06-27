import 'package:flame/components.dart';
import 'package:political_think/games/gemtd/common/extensions.dart';
import 'package:political_think/games/gemtd/gemtdgame/ability/ability.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gem_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/weapon_settings.dart';

//
// No longer primary class!
//
class Defense extends GemComponent {
  Defense({Vector2? position, bool hidden = false})
      : super(position: position, hideSprite: hidden);

  @override
  GemAttributes settings = DefenseSettings();

  @override
  Future<void>? onLoad() async {
    await super.onLoad();
  }
}

class DefenseSettings extends GemAttributes {
  @override
  CityType gemType = CityType.SAMERICA;

  // SpaceX
  // Blue Origin
  // Raytheon
  // Northrop Grumman
  // Rolls-Royce

  @override
  List<String> names = [
    "General Electric",
    "Airbus",
    "Lockheed",
    "Boeing",
    "SpaceX",
    "Rolls-Royce",
  ];

  @override
  double get projectileSpeed => 1.8;

  @override
  double get projectileSizeX => 0.21;

  @override
  String get projectilePath => "weapon/Missile.png";

  @override
  String get explosionImage => "weapon/defense_explosion.png";

  @override
  double get explosionStepTime => 0.08;

  @override
  double get explosionSizeX => 2.7;

  @override
  double get explosionSizeY => 2.7;

  @override
  int get explosionColumns => 6;

  @override
  int get explosionRows => 1;

  @override
  bool get aoe => true;

  final attackRange = [2.5, 2.6, 2.7, 2.8, 2.9];
  @override
  double baseRange(int level) {
    return attackRange.getByLevel(level);
  }

  final attackSpeed = [0.2, 0.3, 0.4, 0.5, 0.6];
  @override
  double baseAttackSpeed(int level) {
    return attackSpeed.getByLevel(level);
  }

  @override
  double baseDamage(int level) => 9.0 + level * 5;

  @override
  Set<Ability> abilities(int level, GemComponent caster) => {
        Burn(level: level + 1, caster: caster),
      };
}
