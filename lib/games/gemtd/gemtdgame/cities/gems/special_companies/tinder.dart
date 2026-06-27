import 'package:flame/components.dart';
import 'package:political_think/games/gemtd/gemtdgame/ability/ability.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gem_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gems/asean/asean.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gems/easia/easia.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gems/mena/mena.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/weapon_settings.dart';

class Tinder extends GemComponent {
  Tinder({Vector2? position}) : super(position: position);

  @override
  GemAttributes settings = TinderSettings();

  @override
  int get level => 3;

  @override
  Future<void>? onLoad() async {
    await super.onLoad();
  }
}

class TinderSettings extends GemAttributes {
  @override
  List<String> names = ["Tinder"];

  @override
  String name(int level) => names[0];

  @override
  CityType gemType = CityType.MENA;

  final _base = Mena()..level = 3;

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
  bool get aoe => _base.settings.aoe;

  @override
  int projectileColumns(level) => _base.settings.projectileColumns(level);

  @override
  int projectileRows(level) => _base.settings.projectileRows(level);

  @override
  bool get projectLoop => _base.settings.projectLoop;

  @override
  double get projectileStepTime => _base.settings.projectileStepTime;

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
        //Affection(caster: caster, level: level),
        Religion(caster: caster, level: level),
      };
}
