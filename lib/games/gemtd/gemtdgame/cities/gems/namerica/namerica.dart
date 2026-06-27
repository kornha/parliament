import 'dart:math';

import 'package:flame/components.dart';
import 'package:political_think/games/gemtd/gemtdgame/ability/ability.dart';
import 'package:political_think/games/gemtd/gemtdgame/base/game_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/barrel_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/bullet_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gem_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/weapon_settings.dart';
import 'package:political_think/games/gemtd/gemtdgame/game/game_constants.dart';

class NAmerica extends GemComponent {
  NAmerica({Vector2? position, bool hidden = false})
      : super(position: position, hideSprite: hidden);

  @override
  GemAttributes settings = NAmericaSettings();

  @override
  get currentImagePath => "city/${name.toLowerCase()}.png";

  @override
  Future<void>? onLoad() async {
    await super.onLoad();
  }
}

class NAmericaSettings extends GemAttributes {
  @override
  CityType gemType = CityType.NAMERICA;

  // HSBC
  // Barclays
  // Citigroup
  // Morgan Stanley
  // UBS
  // Credit Suisse

  @override
  List<String> names = [
    "Philadelphia",
    "Toronto",
    "Miami",
    "San Francisco",
    "Los Angeles",
    "New York",
  ];

  @override
  List<String> countryCodes(int level) {
    switch (level) {
      case 2:
        return ["CA"]; // Toronto
      default:
        return ["US"];
    }
  }

  @override
  String get projectilePath => "weapon/finance_bullet.png";

  @override
  double baseDamage(int level) => 3.2 + level * 1.85;

  // Capitalism (chance ±damage) is the shared spine — on everyone EXCEPT
  // San Francisco (Venture is the extreme version) and Toronto (non-RNG).
  // Philadelphia(Capitalism) -> Toronto(Immigration) -> Miami(Crypto) ->
  // San Francisco(Venture) -> Los Angeles(Hollywood) -> New York(Wall Street).
  @override
  Set<Ability> abilities(int level, GemComponent caster) {
    switch (level) {
      case 1:
        return {
          Capitalism(level: level, caster: caster),
        };
      case 2:
        return {
          Immigration(level: level, caster: caster),
        };
      case 3:
        return {
          Caffeination(caster: caster, level: level), // Crypto: pump-and-dump
          Capitalism(level: level, caster: caster),
        };
      case 4:
        return {
          VentureCapitalism(level: level, caster: caster),
        };
      case 5:
        return {
          Hollywood(level: level, caster: caster),
          Capitalism(level: level, caster: caster),
        };
      default:
        return {
          WallStreet(level: level, caster: caster),
          Capitalism(level: level, caster: caster),
        };
    }
  }
}
