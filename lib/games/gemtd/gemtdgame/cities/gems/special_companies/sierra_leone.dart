import 'package:flame/components.dart';
import 'package:political_think/games/gemtd/gemtdgame/ability/ability.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gem_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/weapon_settings.dart';

// Africa special — Blood Diamond: huge damage + bounty, drains capital per attack.
final sierra_leone_recipe = (
  cities: ["Johannesburg", "Kinshasa", "Medellin"],
  gem: SierraLeone(),
);

class SierraLeone extends GemComponent {
  SierraLeone({Vector2? position}) : super(position: position);

  @override
  GemAttributes settings = SierraLeoneSettings();

  @override
  get currentImagePath => "flags/${countryCodes.first.toLowerCase()}.png";

  @override
  int get level => 6;
}

class SierraLeoneSettings extends GemAttributes {
  @override
  CityType gemType = CityType.AFRICA;

  @override
  List<String> names = ["Sierra Leone"];

  @override
  String name(int level) => names[0];

  @override
  List<String> countryCodes(int level) => ["SL"];

  @override
  double baseAttackSpeed(int level) => 1.2;
  @override
  double baseRange(int level) => 3.0;
  @override
  double baseDamage(int level) => 5.0 + level * 1.5;
  @override
  double get projectileSpeed => 5.0;
  @override
  String get projectilePath => "weapon/chevron.png";
  @override
  double get projectileSizeX => 0.5;
  @override
  double get projectileSizeY => 0.5;
  @override
  bool get projectLoop => false;
  @override
  int projectileColumns(level) => 1;
  @override
  int projectileRows(level) => 6;
  @override
  String get explosionImage => "weapon/auto_explosion.png";
  @override
  int get explosionColumns => 1;
  @override
  int get explosionRows => 1;

  @override
  Set<Ability> abilities(int level, GemComponent caster) {
    final a = {BloodDiamond(level: level, caster: caster)};
    for (final ab in a) {
      ab.gemType = gemType;
      ab.buff?.gemType = gemType;
    }
    return a;
  }
}
