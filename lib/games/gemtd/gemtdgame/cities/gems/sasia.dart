import 'package:flame/components.dart';
import 'package:political_think/games/gemtd/common/extensions.dart';
import 'package:political_think/games/gemtd/gemtdgame/ability/ability.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gem_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/weapon_settings.dart';

class SAsia extends GemComponent {
  SAsia({Vector2? position, bool hidden = false})
      : super(position: position, hideSprite: hidden);

  @override
  GemAttributes settings = SAsiaSettings();

  @override
  get currentImagePath => "city/${name.toLowerCase()}.png";

  @override
  Future<void>? onLoad() async {
    await super.onLoad();
  }
}

class SAsiaSettings extends GemAttributes {
  @override
  CityType gemType = CityType.SASIA;

  @override
  List<String> names = [
    "Colombo",
    "Islamabad",
    "Dhaka",
    "Kathmandu",
    "Delhi",
    "Mumbai",
  ];

  @override
  String get projectilePath => "weapon/dining_bullet.png";

  @override
  String get explosionImage => "weapon/auto_explosion.png";

  @override
  int get explosionRows => 1;

  @override
  int get explosionColumns => 1;

  @override
  double get projectileSpeed => super.projectileSpeed;

  final attackSpeed = [1.2, 1.4, 1.6, 1.8, 2.0, 2.2];
  @override
  double baseAttackSpeed(int level) {
    return attackSpeed.getByLevel(level);
  }

  final attackRange = [1.5, 1.6, 1.7, 1.8, 1.9, 2.0];
  @override
  double baseRange(int level) {
    return attackRange.getByLevel(level);
  }

  @override
  double baseDamage(int level) => level * 0.4 + 0.85;

  @override
  Set<Ability> abilities(int level, GemComponent caster) {
    switch (level) {
      case 1:
        return {
          Poison(level: level, caster: caster),
          Serendipity(level: level, caster: caster),
        };
      default:
        return {
          Poison(level: level, caster: caster),
        };
    }
  }
}
