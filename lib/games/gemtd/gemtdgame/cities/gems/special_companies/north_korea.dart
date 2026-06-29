import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:political_think/games/gemtd/gemtdgame/ability/ability.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gem_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/weapon_settings.dart';

// East Asia special — Juche: a self-reliant loner. Receives NO allied auras and
// has no spine; fires a very slow missile with a devastating atomic blast.
class NorthKorea extends GemComponent {
  NorthKorea({Vector2? position}) : super(position: position);

  @override
  GemAttributes settings = NorthKoreaSettings();

  @override
  get currentImagePath => "flags/${countryCodes.first.toLowerCase()}.png";

  @override
  int get level => 6;
}

class NorthKoreaSettings extends GemAttributes {
  @override
  CityType gemType = CityType.EASIA;

  @override
  List<String> names = ["North Korea"];

  @override
  String name(int level) => names[0];

  @override
  List<String> countryCodes(int level) => ["KP"];

  // Slow, heavy, devastating.
  @override
  double baseAttackSpeed(int level) => 0.3;
  @override
  double baseRange(int level) => 4.0;
  @override
  double baseDamage(int level) => 40.0 + level * 12.0;

  // A slow missile.
  @override
  double get projectileSpeed => 2.2;
  @override
  String get projectilePath => "weapon/finance_bullet.png";
  @override
  double get projectileSizeX => 0.6;
  @override
  double get projectileSizeY => 0.6;
  @override
  bool get projectLoop => false;
  @override
  int projectileColumns(level) => 1;
  @override
  int projectileRows(level) => 1;
  @override
  bool get canHitIntermediateTargets => false;

  // ...with a huge atomic blast.
  @override
  bool get aoe => true;
  @override
  String get explosionImage => "weapon/coinbase_explosion.png";
  @override
  int get explosionColumns => 6;
  @override
  int get explosionRows => 1;
  @override
  double get explosionSizeX => 3.2;
  @override
  double get explosionSizeY => 3.2;

  @override
  Set<Ability> abilities(int level, GemComponent caster) {
    final a = {Juche(level: level, caster: caster)};
    for (final ab in a) {
      ab.gemType = gemType;
      ab.buff?.gemType = gemType;
    }
    return a;
  }
}

// Juche: self-reliance. Strips any buff cast by another tower (receives no
// auras) — North Korea stands alone.
class Juche extends Ability {
  Juche({required super.caster, required super.level});

  @override
  void onAuraScan(Set<GemComponent> gems) {
    caster.buffs.removeWhere((b) => b.caster != caster);
  }

  @override
  String name = "Juche";

  @override
  String description =
      "Self-reliant: receives no allied auras. Fires a slow missile with a "
      "devastating atomic blast.";

  @override
  String get subDescription => "Immune to allied auras; massive splash damage.";

  @override
  IconData icon = FontAwesomeIcons.radiation.data;

  @override
  CityType gemType = CityType.EASIA;
}
