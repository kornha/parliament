import 'package:flame/components.dart';
import 'package:political_think/games/gemtd/gemtdgame/ability/ability.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gem_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gems/mena/mena.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/weapon_settings.dart';

// MENA special — Holy Land: an attack-speed aura where the faiths converge.
final jerusalem_recipe = (
  cities: ["Tel Aviv", "New York", "Rome"],
  gem: Jerusalem(),
);

class Jerusalem extends GemComponent {
  Jerusalem({Vector2? position}) : super(position: position);

  @override
  GemAttributes settings = JerusalemSettings();

  @override
  get currentImagePath => "city/${name.toLowerCase()}.png";

  @override
  int get level => 6;
}

class JerusalemSettings extends GemAttributes {
  @override
  CityType gemType = CityType.MENA;

  final _base = Mena()..level = 6;

  @override
  List<String> names = ["Jerusalem"];

  @override
  String name(int level) => names[0];

  @override
  List<String> countryCodes(int level) => ["IL"];

  @override
  double baseAttackSpeed(int level) => _base.settings.baseAttackSpeed(level);

  @override
  double baseRange(int level) => 3.5;

  @override
  double baseDamage(int level) => _base.settings.baseDamage(level);

  @override
  Set<Ability> abilities(int level, GemComponent caster) {
    final a = {HolyLand(level: level, caster: caster)};
    for (final ab in a) {
      ab.gemType = gemType;
      ab.buff?.gemType = gemType;
    }
    return a;
  }
}
