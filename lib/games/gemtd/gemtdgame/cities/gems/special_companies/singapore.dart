import 'package:flame/components.dart';
import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:political_think/games/gemtd/gemtdgame/ability/ability.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gem_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gems/asean/asean.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/weapon_settings.dart';

// ASEAN special — Diplomacy: a hub that amplifies every buff on nearby allied
// towers (rehomes MENA's cut Cedars-of-Lebanon mechanic).
class Singapore extends GemComponent {
  Singapore({Vector2? position}) : super(position: position);

  @override
  GemAttributes settings = SingaporeSettings();

  @override
  get currentImagePath => "flags/${countryCodes.first.toLowerCase()}.png";

  @override
  int get level => 6;
}

class SingaporeSettings extends GemAttributes {
  @override
  CityType gemType = CityType.ASEAN;

  final _base = Asean()..level = 6;

  @override
  List<String> names = ["Singapore"];

  @override
  String name(int level) => names[0];

  @override
  List<String> countryCodes(int level) => ["SG"];

  @override
  double baseAttackSpeed(int level) => _base.settings.baseAttackSpeed(level);
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
    final a = {Diplomacy(level: level, caster: caster)};
    for (final ab in a) {
      ab.gemType = gemType;
      ab.buff?.gemType = gemType;
    }
    return a;
  }
}

// Diplomacy: amplifies the buffs of all nearby allied towers.
class Diplomacy extends CedarsOfLebanon {
  Diplomacy({required super.caster, required super.level});

  @override
  String name = "Diplomacy";

  @override
  String description = "Amplifies the buffs of all nearby allied towers.";

  @override
  IconData icon = FontAwesomeIcons.handshake.data;

  @override
  CityType gemType = CityType.ASEAN;
}
