import 'package:flame/game.dart';
import 'package:political_think/games/gemtd/gemtdgame/ability/ability.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gem_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/weapon_settings.dart';

import '../../city_config.dart';
import 'asean.dart';

const hanoi = (level: 2, city: "Hanoi", countryCode: "VN");

Set<Ability> hanoi_abilities(HanoiSettings settings, int level,
        GemComponent caster, CityConfig config) =>
    {
      Allure(level: level, caster: caster),
      NorthAndSouth(level: level, caster: caster),
    };

final hanoi_recipe = (
  cities: [phnom_penh.city, phnom_penh.city, phnom_penh.city],
  gem: Hanoi(),
);

class Hanoi extends GemComponent {
  Hanoi({Vector2? position, bool hidden = false})
      : super(position: position, hideSprite: hidden);

  @override
  GemAttributes settings = HanoiSettings();

  @override
  get currentImagePath => "city/${name.toLowerCase()}.png";

  @override
  int get level => hanoi.level;
}

class HanoiSettings extends GemAttributes {
  @override
  CityType gemType = CityType.ASEAN;

  final _base = Asean()..level = hanoi.level;

  @override
  List<String> names = ["Hanoi"];

  @override
  List<String> countryCodes(int level) => [hanoi.countryCode];

  @override
  String name(int level) => names[0];

  @override
  bool get aoe => true;

  @override
  double baseAttackSpeed(int level) => _base.settings.baseAttackSpeed(level);

  @override
  double baseRange(int level) => _base.settings.baseRange(level);

  @override
  double baseDamage(int level) => _base.settings.baseDamage(level);

  @override
  Set<Ability> abilities(int level, GemComponent caster) =>
      hanoi_abilities(this, level, caster, hanoi);
}
