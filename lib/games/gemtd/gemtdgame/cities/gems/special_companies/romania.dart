import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:political_think/games/gemtd/common/extensions.dart';
import 'package:political_think/games/gemtd/gemtdgame/ability/ability.dart';
import 'package:political_think/games/gemtd/gemtdgame/ability/buff.dart' as bf;
import 'package:political_think/games/gemtd/gemtdgame/base/game_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gem_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gems/eeurope/eeurope.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/weapon_settings.dart';
import 'package:political_think/games/gemtd/gemtdgame/enemy/enemy_component.dart';

// E. Europe special — Vampire Economy: drains damage from every allied
// tower in its aura and adds all of it to itself.
// Recipe: Poland + Israel + Latvia.
class Romania extends GemComponent {
  Romania({Vector2? position}) : super(position: position);

  @override
  GemAttributes settings = RomaniaSettings();

  @override
  get currentImagePath => "flags/${countryCodes.first.toLowerCase()}.png";

  @override
  int get level => 6;
}

class RomaniaSettings extends GemAttributes {
  @override
  CityType gemType = CityType.EEUROPE;

  final _base = EEurope()..level = 6;

  @override
  List<String> names = ["Romania"];

  @override
  String name(int level) => names[0];

  @override
  List<String> countryCodes(int level) => ["RO"];

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
    final a = {VampireEconomy(level: level, caster: caster)};
    for (final ab in a) {
      ab.gemType = gemType;
      ab.buff?.gemType = gemType;
    }
    return a;
  }
}

// Vampire Economy: allied towers in the aura lose a cut of their damage;
// Romania gains that cut per drained ally. It feeds on its neighbors.
class VampireEconomy extends Ability {
  VampireEconomy({required super.caster, required super.level});

  static const drainPerLevel = [0.10, 0.11, 0.12, 0.13, 0.14, 0.15];

  int _drainedCount = 0;

  @override
  bool get alliesAura => true;

  // The drain applied to nearby allies.
  @override
  bf.Buff? get buff => bf.DamageMultiple(
        caster: caster,
        level: level,
        overrideMultiplier: 1 - drainPerLevel.getByLevel(level),
      )
        ..name = name
        ..icon = icon
        ..gemType = gemType
        ..renderType = bf.RenderType.GRID;

  @override
  void onAuraScan(Set<GemComponent> gems) {
    // Don't drain (or count) ourselves.
    final others = gems.where((g) => g != caster).toSet();
    _drainedCount = others.length;
    super.onAuraScan(others);
  }

  // The feast: gain the drained cut once per drained ally.
  @override
  GameComponent? onEnemyAttack(GemComponent gem, EnemyComponent primaryTarget,
      Set<GameComponent> targets) {
    if (_drainedCount > 0) {
      gem.buffs.add(bf.DamageMultiple(
        caster: caster,
        level: level,
        overrideMultiplier:
            1 + drainPerLevel.getByLevel(level) * _drainedCount,
      )
        ..name = name
        ..icon = icon
        ..gemType = gemType);
    }
    return null;
  }

  @override
  String name = "Vampire Economy";

  @override
  String description =
      "Drains damage from every allied tower in range and adds all of it "
      "to itself.";

  @override
  String get subDescription =>
      "Allies in range: -${drainPerLevel.map((e) => "${(e * 100).toStringAsFixed(0)}%").join("/")} damage; "
      "Romania gains that per drained ally.";

  @override
  IconData icon = FontAwesomeIcons.droplet.data;

  @override
  CityType gemType = CityType.EEUROPE;
}
