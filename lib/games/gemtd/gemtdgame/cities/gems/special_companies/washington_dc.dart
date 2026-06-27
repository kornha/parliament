import 'package:flame/components.dart';
import 'package:political_think/games/gemtd/gemtdgame/ability/ability.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gem_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gems/namerica/namerica.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/weapon_settings.dart';

// North America special — Deep State: invisible shots, random targets, random
// damage. Total chaos.
final washington_dc_recipe = (
  cities: ["Beijing", "Moscow", "Philadelphia"],
  gem: WashingtonDC(),
);

class WashingtonDC extends GemComponent {
  WashingtonDC({Vector2? position}) : super(position: position);

  @override
  GemAttributes settings = WashingtonDCSettings();

  @override
  get currentImagePath => "city/${name.toLowerCase()}.png";

  @override
  int get level => 6;
}

class WashingtonDCSettings extends GemAttributes {
  @override
  CityType gemType = CityType.NAMERICA;

  final _base = NAmerica()..level = 6;

  @override
  List<String> names = ["Washington DC"];

  @override
  String name(int level) => names[0];

  @override
  List<String> countryCodes(int level) => ["US"];

  @override
  double baseAttackSpeed(int level) => _base.settings.baseAttackSpeed(level);
  @override
  double baseRange(int level) => 3.0;
  @override
  double baseDamage(int level) => _base.settings.baseDamage(level);

  // Invisible projectile + bomb explosion on impact.
  @override
  double get projectileSpeed => 9.0;
  @override
  String get projectilePath => "weapon/empty_bullet.png";
  @override
  int projectileColumns(level) => 1;
  @override
  int projectileRows(level) => 1;
  @override
  bool get projectLoop => false;
  @override
  bool get canHitIntermediateTargets => false;
  @override
  String get explosionImage => "weapon/coinbase_explosion.png";
  @override
  int get explosionColumns => 6;
  @override
  int get explosionRows => 1;
  @override
  double get explosionSizeX => 1.2;
  @override
  double get explosionSizeY => 1.2;

  @override
  Set<Ability> abilities(int level, GemComponent caster) {
    final a = {
      FullMoon(level: level, caster: caster), // random target + huge range
      Capitalism(level: level, caster: caster), // random damage
    };
    for (final ab in a) {
      ab.gemType = gemType;
      ab.buff?.gemType = gemType;
    }
    return a;
  }
}
