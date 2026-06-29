import 'package:flame/components.dart';
import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:political_think/games/gemtd/gemtdgame/ability/ability.dart';
import 'package:political_think/games/gemtd/gemtdgame/ability/buff.dart' as bf;
import 'package:political_think/games/gemtd/gemtdgame/cities/gem_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gems/mena/mena.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/weapon_settings.dart';

// MENA special — Propaganda: an aura that sets nearby allied towers to Qatar's
// exact tier (level), homogenizing them up or down.
class Qatar extends GemComponent {
  Qatar({Vector2? position}) : super(position: position);

  @override
  GemAttributes settings = QatarSettings();

  @override
  get currentImagePath => "flags/${countryCodes.first.toLowerCase()}.png";

  @override
  int get level => 6;
}

class QatarSettings extends GemAttributes {
  @override
  CityType gemType = CityType.MENA;

  final _base = Mena()..level = 6;

  @override
  List<String> names = ["Qatar"];

  @override
  String name(int level) => names[0];

  @override
  List<String> countryCodes(int level) => ["QA"];

  @override
  double baseAttackSpeed(int level) => _base.settings.baseAttackSpeed(level);
  @override
  double baseRange(int level) => 4.0;
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
    final a = {Propaganda(level: level, caster: caster)};
    for (final ab in a) {
      ab.gemType = gemType;
      ab.buff?.gemType = gemType;
    }
    return a;
  }
}

// Propaganda: broadcasts Qatar's tier onto nearby allied towers — their stats
// scale to Qatar's level (see StatusManager.computeGemStatus / PropagandaBuff).
class Propaganda extends Ability {
  Propaganda({required super.caster, required super.level});

  @override
  bool get alliesAura => true;

  @override
  bf.Buff? get buff => bf.PropagandaBuff(
        caster: caster,
        level: level,
        targetLevel: caster.level,
      )
        ..name = name
        ..icon = icon
        ..gemType = gemType;

  @override
  String name = "Propaganda";

  @override
  String description =
      "Sets nearby allied towers to Qatar's exact tier — homogenizing them up or down.";

  @override
  String get subDescription => "Nearby allies scale to Qatar's level.";

  @override
  IconData icon = FontAwesomeIcons.bullhorn.data;

  @override
  CityType gemType = CityType.MENA;
}
