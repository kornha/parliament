import 'package:flame/components.dart';
import 'package:political_think/games/gemtd/gemtdgame/ability/ability.dart';
import 'package:political_think/games/gemtd/gemtdgame/ability/buff.dart' as bf;
import 'package:political_think/games/gemtd/gemtdgame/cities/gem_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gems/easia/easia.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/weapon_settings.dart';

// East Asia special — Already Tomorrow: every attack strikes twice.
class AlreadyTomorrow extends SequentialAttack {
  AlreadyTomorrow({required super.caster, required super.level});

  @override
  String name = "Already Tomorrow";

  @override
  bf.SequentialAttack createBuff() => bf.SequentialAttack(
        caster: caster,
        level: level,
        attacksNumPerLevel: const [2, 2, 2, 2, 2, 2],
      );
}

final hongkong_recipe = (
  cities: ["Shanghai", "Shenzhen", "London"],
  gem: HongKong(),
);

class HongKong extends GemComponent {
  HongKong({Vector2? position}) : super(position: position);

  @override
  GemAttributes settings = HongKongSettings();

  @override
  get currentImagePath => "city/${name.toLowerCase()}.png";

  @override
  int get level => 6;
}

class HongKongSettings extends GemAttributes {
  @override
  CityType gemType = CityType.EASIA;

  final _base = EAsia()..level = 6;

  @override
  List<String> names = ["Hong Kong"];

  @override
  String name(int level) => names[0];

  @override
  List<String> countryCodes(int level) => ["HK"];

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
  Set<Ability> abilities(int level, GemComponent caster) {
    final a = {AlreadyTomorrow(level: level, caster: caster)};
    for (final ab in a) {
      ab.gemType = gemType;
      ab.buff?.gemType = gemType;
    }
    return a;
  }
}
