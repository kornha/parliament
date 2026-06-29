import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:political_think/games/gemtd/common/extensions.dart';
import 'package:political_think/games/gemtd/gemtdgame/ability/ability.dart';
import 'package:political_think/games/gemtd/gemtdgame/ability/buff.dart' as bf;
import 'package:political_think/games/gemtd/gemtdgame/base/game_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gem_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gems/namerica/namerica.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/weapon_settings.dart';
import 'package:political_think/games/gemtd/gemtdgame/enemy/enemy_component.dart';

// North America special — CECOT: a chance to imprison (instantly remove) an
// enemy — but it pays out no capital (paired with the Capitalism spine).
class ElSalvador extends GemComponent {
  ElSalvador({Vector2? position}) : super(position: position);

  @override
  GemAttributes settings = ElSalvadorSettings();

  @override
  get currentImagePath => "flags/${countryCodes.first.toLowerCase()}.png";

  @override
  int get level => 6;
}

class ElSalvadorSettings extends GemAttributes {
  @override
  CityType gemType = CityType.NAMERICA;

  final _base = NAmerica()..level = 6;

  @override
  List<String> names = ["El Salvador"];

  @override
  String name(int level) => names[0];

  @override
  List<String> countryCodes(int level) => ["SV"];

  @override
  double baseAttackSpeed(int level) => 1.0;
  @override
  double baseRange(int level) => 3.5;
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
  Set<Ability> abilities(int level, GemComponent caster) {
    final a = {
      Capitalism(level: level, caster: caster),
      CECOT(level: level, caster: caster),
    };
    for (final ab in a) {
      ab.gemType = gemType;
      ab.buff?.gemType = gemType;
    }
    return a;
  }
}

// CECOT: a chance to imprison an enemy — instantly removing it from the board.
// Imprisoned enemies yield no capital (their bounty is zeroed before removal).
class CECOT extends Ability {
  CECOT({required super.caster, required super.level});

  static var chancePerLevel = [0.06, 0.08, 0.10, 0.12, 0.14, 0.16];

  @override
  double? get baseChance => chancePerLevel.getByLevel(level);

  final Random _r = Random();

  @override
  GameComponent? onEnemyAttack(GemComponent gem, EnemyComponent primaryTarget,
      Set<GameComponent> targets) {
    if (_r.nextDouble() < (currentChance ?? 0)) {
      // Zero the bounty (persistent buff + immediate set) so the kill pays out
      // nothing, then deliver a lethal blow that overcomes armor.
      primaryTarget.buffs.add(bf.BountyMultiple(
        caster: caster,
        level: level,
        overrideMultiplier: -1.0,
      ));
      primaryTarget.capital = 0;
      primaryTarget.receiveDamage(primaryTarget.maxLife * 100, {}, gem);
    }
    return null;
  }

  @override
  String name = "CECOT";

  @override
  String description =
      "A chance to imprison (instantly remove) an enemy — but it yields no capital.";

  @override
  String get subDescription =>
      "${chancePerLevel.map((e) => "${(e * 100).toStringAsFixed(0)}%").join("/")} chance to imprison.";

  @override
  IconData icon = FontAwesomeIcons.handcuffs.data;

  @override
  CityType gemType = CityType.NAMERICA;
}
