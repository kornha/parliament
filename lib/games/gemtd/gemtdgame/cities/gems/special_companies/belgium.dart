import 'package:flame/components.dart';
import 'package:political_think/games/gemtd/gemtdgame/ability/ability.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gem_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gems/weurope/weurope.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/weapon_settings.dart';

// Western Europe special — Bureaucracy: reaches the entire board, but grinds
// through it very slowly (paired with the Socialism share-attack spine).
class Belgium extends GemComponent {
  Belgium({Vector2? position}) : super(position: position);

  @override
  GemAttributes settings = BelgiumSettings();

  @override
  get currentImagePath => "flags/${countryCodes.first.toLowerCase()}.png";

  @override
  int get level => 6;
}

class BelgiumSettings extends GemAttributes {
  @override
  CityType gemType = CityType.WEUROPE;

  final _base = WEurope()..level = 6;

  @override
  List<String> names = ["Belgium"];

  @override
  String name(int level) => names[0];

  @override
  List<String> countryCodes(int level) => ["BE"];

  // Whole board, slowly.
  @override
  double baseAttackSpeed(int level) => 0.5;
  @override
  double baseRange(int level) => 15.0;
  @override
  double baseDamage(int level) => _base.settings.baseDamage(level);
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
    final a = {
      Socialism(level: level, caster: caster),
      Bureaucracy(level: level, caster: caster),
    };
    for (final ab in a) {
      ab.gemType = gemType;
      ab.buff?.gemType = gemType;
    }
    return a;
  }
}
