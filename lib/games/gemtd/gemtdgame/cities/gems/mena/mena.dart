import 'package:flame/components.dart';
import 'package:political_think/games/gemtd/gemtdgame/ability/ability.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gem_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/weapon_settings.dart';

class Mena extends GemComponent {
  Mena({Vector2? position, bool hidden = false})
      : super(position: position, hideSprite: hidden);

  @override
  GemAttributes settings = MenaSettings();

  @override
  get currentImagePath => "city/${name.toLowerCase()}.png";

  @override
  Future<void>? onLoad() async {
    await super.onLoad();
  }
}

class MenaSettings extends GemAttributes {
  @override
  CityType gemType = CityType.MENA;

  @override
  int projectileColumns(level) => 1;

  // Support cities are pure auras (no attack). Tel Aviv (level 5) is the lone
  // attacker — the venture-capital gamble.
  @override
  double baseRange(int level) => level == 5 ? 3.0 : 2.5;

  @override
  double baseDamage(int level) => level == 5 ? 3.0 + level * 1.5 : 0.0;

  @override
  double baseAttackSpeed(int level) => level == 5 ? 1.0 : 0.0;

  @override
  int projectileRows(level) => 6;

  @override
  String get projectilePath => "weapon/chevron.png";

  @override
  double get projectileSizeX => 0.5;

  @override
  double get projectileSizeY => 0.5;

  // LinkedIn
  // Myspace
  // YouTube

  @override
  List<String> names = [
    "Damascus",
    "Beirut",
    "Cairo",
    "Riyadh",
    "Tel Aviv",
    "Dubai",
  ];

  @override
  List<String> countryCodes(int level) {
    switch (level) {
      case 1:
        return ["SY"];
      case 2:
        return ["LB"];
      case 3:
        return ["EG"];
      case 4:
        return ["SA"];
      case 5:
        return ["IL"];
      default:
        return ["AE"];
    }
  }

  // Religion (ally damage aura) is the shared spine; MENA never attacks except
  // Tel Aviv. Damascus(Religion) -> Beirut(Cedars) -> Cairo(Sphinx) ->
  // Riyadh(Black Gold/Oiled) -> Tel Aviv(Venture gamble) -> Dubai(economy).
  @override
  Set<Ability> abilities(int level, GemComponent caster) {
    final Set<Ability> abilities = switch (level) {
      1 => {Religion(level: level, caster: caster)},
      2 => {
          Religion(level: level, caster: caster),
          CedarsOfLebanon(level: level, caster: caster),
        },
      3 => {
          Religion(level: level, caster: caster),
          Sphinx(level: level, caster: caster),
        },
      4 => {
          Religion(level: level, caster: caster),
          BlackGold(level: level, caster: caster),
        },
      5 => {
          VentureCapitalism(level: level, caster: caster),
        },
      _ => {
          Religion(level: level, caster: caster),
          GoldenSouk(level: level, caster: caster),
        },
    };
    abilities.forEach((a) {
      a.gemType = gemType;
      a.buff?.gemType = gemType;
    });
    return abilities;
  }
}
