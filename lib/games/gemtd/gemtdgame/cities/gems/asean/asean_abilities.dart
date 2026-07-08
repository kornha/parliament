part of 'asean.dart';

Set<Ability> asean_abilities(AseanSettings settings, int level,
        GemComponent caster, CityConfig config) =>
    switch (config) {
      // Cambodia (1) — spine only: pure Allure (reduces enemy armor).
      cambodia => {
          Allure(level: level, caster: caster),
        },
      // Vietnam (2) — sequential combo attack, on top of the spine.
      vietnam => {
          Allure(level: level, caster: caster),
          SouthAndNorth(level: level, caster: caster),
        },
      // Philippines (3) — Thousand Islands: attack speed up, range down.
      philippines => {
          Allure(level: level, caster: caster),
          ThousandIslands(level: level, caster: caster),
        },
      // Indonesia (4) — Thousand Islands (archipelago twin of the Philippines).
      indonesia => {
          Allure(level: level, caster: caster),
          ThousandIslands(level: level, caster: caster),
        },
      // Malaysia (5) — Petronas oil aura: one spell that coats enemies in oil
      // (slow + amplified damage taken), cannot fire a projectile (no Allure).
      malaysia => {
          Petronas(level: level, caster: caster),
        },
      // Thailand (6, capstone) — Beautiful Chaos: huge range + random target +
      // fast hidden projectile (ThailandSettings sets empty_bullet + coin
      // explosion + AoE-less single hit).
      thailand => {
          Allure(level: level, caster: caster),
          BeautifulChaos(level: level, caster: caster),
        },
      _ => throw UnimplementedError(
          'Unknown ability for level $level and config $config'),
    };

enum SouthAndNorthType { south, north }

// If the city is in range of Hanoi (North & South ability), this city fires a
// sequential attack.
class SouthAndNorth extends SequentialAttack {
  SouthAndNorth(
      {required super.caster,
      required super.level,
      this.type = SouthAndNorthType.south});

  final SouthAndNorthType type;

  var _hasPairCity = false;

  @override
  bool mayApplyBuff() => _hasPairCity;

  @override
  late String name = switch (type) {
    SouthAndNorthType.south => "South & North",
    SouthAndNorthType.north => "North & South",
  };

  @override
  late String description = switch (type) {
    SouthAndNorthType.south =>
      "If the city is in range of ${hanoi.city} (North & South ability), this city fires a sequential attack.",
    SouthAndNorthType.north =>
      "If the city is in range of ${vietnam.city} (South & North ability), this city fires a sequential attack.",
  };

  @override
  CityType gemType = CityType.ASEAN;

  @override
  void onAuraScan(Set<GemComponent> gems) {
    _hasPairCity = gems.any(checkIsPairCity);
    super.onAuraScan(gems);
  }

  bool checkIsPairCity(GemComponent gem) => switch (type) {
        SouthAndNorthType.south => gem is Hanoi,
        SouthAndNorthType.north => gem.settings is AseanSettings &&
            (gem.settings as AseanSettings).cityConfig == vietnam,
      };

  @override
  bf.SequentialAttack createBuff() => bf.SequentialAttack(
        caster: caster,
        // hardcode level to 1 (as Alex wanted) for Hanoi and Vietnam
        level: 1,
      );
}

// If the city is in range of Ho Chi Minh (South & North ability), this city
// fires a sequential attack.
class NorthAndSouth extends SouthAndNorth {
  NorthAndSouth({required super.caster, required super.level})
      : super(type: SouthAndNorthType.north);
}

// Sinking City: Jakarta cannot attack. Increases attack speed of nearby cities.
class SinkingCity extends Ability {
  SinkingCity({required super.caster, required super.level});

  @override
  String name = "Sinking City";

  @override
  String description = "Increases attack speed of nearby cities.";

  @override
  String get subDescription =>
      "${bf.AttackSpeedMultiple.defaultMultipliers.join("/")}x attack speed.";

  @override
  bf.Buff? get buff => bf.AttackSpeedMultiple(
        caster: caster,
        level: level,
      )..gemType = gemType;

  @override
  bool get canAttack => false;

  @override
  bool get alliesAura => true;

  @override
  CityType gemType = CityType.ASEAN;

  @override
  //TODO(find out which icon is appropriate for this ability)
  IconData icon = FontAwesomeIcons.toggleOff.data;
}

// Thousand Islands: Greatly reduces attack range, while increasing attack speed.
class ThousandIslands extends Ability {
  ThousandIslands({required super.caster, required super.level});

  static const attackRangeFraction = <double>[0.70, 0.65, 0.5, 0.45, 0.4, 0.35];
  static const attackSpeedFraction = <double>[3, 3.25, 3.5, 3.75, 4, 4.25];

  @override
  String name = "Thousand Islands";

  @override
  String description =
      "Greatly reduces attack range, while increasing attack speed.";

  @override
  String get subDescription => "${attackSpeedFraction.join("/")}x attack speed."
      "\n${attackRangeFraction.map((e) => (1 / e).toStringAsFixed(1)).join("/")}x range.";

  @override
  bool get worksOnSelf => true;

  @override
  bf.Buff? get buff => bf.AttackSpeedMultiple(
        caster: caster,
        level: level,
        overrideMultiplier: attackSpeedFraction.getByLevel(level),
      )
        ..rangeMultiplier = attackRangeFraction.getByLevel(level)
        ..name = name
        ..icon = icon
        ..gemType = gemType;

  @override
  CityType gemType = CityType.ASEAN;

  @override
  IconData icon = FontAwesomeIcons.arrowUpRightDots.data;
}

// Thailand (capstone) — Beautiful Chaos: keeps Full Moon's huge range + random
// target, rebranded for ASEAN. (FullMoon is left intact in ability.dart for the
// Coinbase / Washington DC specials that also use it.)
class BeautifulChaos extends FullMoon {
  BeautifulChaos({required super.caster, required super.level});

  @override
  String name = "Beautiful Chaos";

  @override
  String description =
      "Greatly increases attack range, but attacks a random target.";

  @override
  CityType gemType = CityType.ASEAN;

  @override
  IconData icon = FontAwesomeIcons.dice.data;
}
