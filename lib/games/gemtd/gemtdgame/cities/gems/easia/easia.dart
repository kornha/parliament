import 'package:flame/components.dart';
import 'package:political_think/games/gemtd/common/extensions.dart';
import 'package:political_think/games/gemtd/gemtdgame/ability/ability.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gem_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/weapon_settings.dart';

class EAsia extends GemComponent {
  EAsia({Vector2? position}) : super(position: position);

  @override
  get currentImagePath => "city/${name.toLowerCase()}.png";

  @override
  GemAttributes settings = EAsiaSettings();

  @override
  Future<void>? onLoad() async {
    await super.onLoad();
  }
}

class EAsiaSettings extends GemAttributes {
  @override
  List<String> names = [
    "Osaka",
    "Shenzhen",
    "Seoul",
    "Beijing",
    "Shanghai",
    "Tokyo",
  ];

  @override
  List<String> countryCodes(int level) {
    switch (level) {
      case 1:
        return ["JP"];
      case 2:
        return ["CN"];
      case 3:
        return ["KR"];
      case 4:
        return ["CN"];
      case 5:
        return ["CN"];
      default:
        return ["JP"];
    }
  }

  @override
  CityType gemType = CityType.EASIA;

  @override
  double baseAttackSpeed(int level) => 0.4 + level * 0.05;

  @override
  bool get canHitIntermediateTargets => false;

  @override
  double get projectileSpeed => 5;

  final List<double> attackRange = [3.3, 3.4, 3.5, 3.6, 3.7, 3.8];
  @override
  double baseRange(int level) => attackRange.getByLevel(level);

  @override
  double baseDamage(int level) => 5.5 + level * 0.5;

  @override
  String get projectilePath => "projectile/easia_projectile.png";

  @override
  double get projectileSizeX => 0.8;

  @override
  double get projectileSizeY => 0.8;

  @override
  int projectileColumns(int level) => 1;

  @override
  int projectileRows(int level) => 5;

  @override
  bool get projectLoop => false;

  @override
  double get projectileStepTime => 0.03;

  @override
  String get explosionImage => "explosion/easia_explosion.png";

  @override
  int get explosionColumns => 6;

  @override
  int get explosionRows => 1;

  @override
  // TODO: implement explosionSizeX
  double get explosionSizeX => 1.2;

  @override
  // TODO: implement explosionSizeX
  double get explosionSizeY => 1.2;

  @override
  double get explosionStepTime => 0.06;

  // Spine: Balance (chance to stun) is shared on every city.
  // Osaka(Balance only) -> Shenzhen(Manufactured Technology) -> Seoul(K-Pop)
  // -> Beijing(People's Republic) -> Shanghai(Red Capitalism) -> Tokyo(Kaizen).
  @override
  Set<Ability> abilities(int level, GemComponent caster) {
    switch (level) {
      case 1:
        return {
          Balance(level: level, caster: caster),
        };
      case 2:
        return {
          Balance(level: level, caster: caster),
          ManufacturedTechnology(level: level, caster: caster),
        };
      case 3:
        return {
          Balance(level: level, caster: caster),
          KPOP(level: level, caster: caster),
        };
      case 4:
        return {
          Balance(level: level, caster: caster),
          PeoplesRepublic(level: level, caster: caster),
        };
      case 5:
        return {
          Balance(level: level, caster: caster),
          RedCapitalism(level: level, caster: caster),
        };
      default:
        return {
          Balance(level: level, caster: caster),
          Kaizen(level: level, caster: caster),
        };
    }
  }
}
