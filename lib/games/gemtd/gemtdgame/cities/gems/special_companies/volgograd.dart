import 'package:flame/components.dart';
import 'package:political_think/games/gemtd/gemtdgame/ability/ability.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gem_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gems/eeurope/eeurope.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/weapon_settings.dart';

final volgograd_recipe = (
  cities: [stPetersburg.city, moscow.city],
  gem: Volgograd(),
);

class Volgograd extends GemComponent {
  Volgograd({Vector2? position}) : super(position: position);

  @override
  GemAttributes settings = VolgogradSettings();

  @override
  int get level => 5;

  @override
  Future<void>? onLoad() async {
    await super.onLoad();
  }
}

class VolgogradSettings extends GemAttributes {
  @override
  List<String> names = ["Volgograd"];

  @override
  String name(int level) => names[0];

  @override
  CityType gemType = CityType.EEUROPE;

  final _base = EEurope()..level = 5;

  @override
  double baseAttackSpeed(int level) => _base.settings.baseAttackSpeed(level);

  @override
  double baseRange(int level) => _base.settings.baseRange(level);

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
  double get explosionSizeX => _base.settings.explosionSizeX;

  @override
  double get explosionSizeY => _base.settings.explosionSizeY;

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
  double get explosionStepTime => _base.settings.explosionStepTime;

  @override
  Set<Ability> abilities(int level, GemComponent caster) => {
        MotherRussia(caster: caster, level: level)..gemType = gemType,
      };
}
