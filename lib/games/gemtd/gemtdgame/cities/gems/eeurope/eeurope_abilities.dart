part of 'eeurope.dart';

// Eastern Europe — Oligarchy / compounding.
// Oligarchy (each consecutive hit on the same enemy compounds attack speed) is
// the shared spine. Each city adds its own compounding debuff (the enemy
// auto-stacks the buff on repeated hits, and StatusManager multiplies by stacks).
// Kyiv(Oligarchy) -> Budapest(Thermal Baths: compound slow)
// -> St Petersburg(Leningrad: compound bounty) -> Prague(Defenestration: compound armor shred)
// -> Warsaw(Uprising: compound vulnerability) -> Moscow(Kremlin: compounding never resets).
Set<Ability> eeurope_abilities(EEuropeSettings settings, int level,
        GemComponent caster, CityConfig config) =>
    switch (config) {
      kyiv => {
          Oligarchy(level: level, caster: caster),
        },
      budapest => {
          Oligarchy(level: level, caster: caster),
          ThermalBaths(level: level, caster: caster),
        },
      stPetersburg => {
          Oligarchy(level: level, caster: caster),
          Leningrad(level: level, caster: caster),
        },
      prague => {
          Oligarchy(level: level, caster: caster),
          Defenestration(level: level, caster: caster),
        },
      warsaw => {
          Oligarchy(level: level, caster: caster),
          Uprising(level: level, caster: caster),
        },
      moscow => {
          Kremlin(level: level, caster: caster),
        },
      _ => throw UnimplementedError(
          'Unknown ability for level $level and config $config'),
    };

// Shared spine: each consecutive hit on the SAME enemy compounds attack speed.
class Oligarchy extends Ability {
  Oligarchy({
    required super.caster,
    required super.level,
    this.neverResets = false,
  });

  static const increasePerLevel = [0.15, 0.2, 0.25, 0.3, 0.35, 0.4];
  static const _max = 50;

  final bool neverResets;
  int count = 0;

  @override
  String name = "Oligarchy";

  @override
  String description =
      "Each consecutive hit on the same enemy increases attack speed.";

  @override
  String get subDescription =>
      "${increasePerLevel.map((e) => "+${(e * 100).toStringAsFixed(0)}%").join("/")} attack speed per hit.";

  @override
  IconData icon = FontAwesomeIcons.chartLine.data;

  @override
  GameComponent? onEnemyAttack(GemComponent gem, EnemyComponent primaryTarget,
      Set<GameComponent> targets) {
    if (neverResets || caster.lastEnemy == primaryTarget) {
      if (count < _max) count++;
    } else {
      count = 0;
    }
    gem.buffs.add(bf.AttackSpeedMultiple(
      caster: caster,
      level: level,
      overrideDurationType: bf.DurationType.ATTACK,
      overrideMultiplier: 1 + count * increasePerLevel.getByLevel(level),
    ));
    return null;
  }

  @override
  CityType gemType = CityType.EEUROPE;
}

// Moscow — Kremlin: the compounding attack speed never resets.
class Kremlin extends Oligarchy {
  Kremlin({required super.caster, required super.level})
      : super(neverResets: true);

  @override
  String name = "Kremlin";

  @override
  String description = "Compounding attack speed that never resets.";

  @override
  IconData icon = FontAwesomeIcons.chessRook.data;
}

// Budapest — Thermal Baths: each consecutive hit compounds a slow.
class ThermalBaths extends Ability {
  ThermalBaths({required super.caster, required super.level});

  static const slowPerStack = [0.03, 0.04, 0.05, 0.06, 0.07, 0.08];

  @override
  bool get worksOnEnemies => true;

  @override
  bf.Buff? get buff => bf.SpeedModify(
        caster: caster,
        level: level,
        modifier: slowPerStack.getByLevel(level),
        overrideBaseDuration: 3,
      )
        ..name = name
        ..icon = icon
        ..gemType = gemType
        ..stacks = 1
        ..renderType = bf.RenderType.GRID;

  @override
  String name = "Thermal Baths";

  @override
  String description = "Each consecutive hit compounds a slow on the enemy.";

  @override
  String get subDescription =>
      "${slowPerStack.map((e) => "${(e * 100).toStringAsFixed(0)}%").join("/")} slow per stack.";

  @override
  IconData icon = FontAwesomeIcons.hotTubPerson.data;

  @override
  CityType gemType = CityType.EEUROPE;
}

// St Petersburg — Leningrad: each consecutive hit compounds the enemy's bounty.
class Leningrad extends Ability {
  Leningrad({required super.caster, required super.level});

  static const bountyPerStack = [0.10, 0.13, 0.16, 0.19, 0.22, 0.25];

  @override
  bool get worksOnEnemies => true;

  @override
  bf.Buff? get buff => bf.BountyMultiple(
        caster: caster,
        level: level,
        overrideMultiplier: bountyPerStack.getByLevel(level),
        overrideBaseDuration: 3,
      )
        ..name = name
        ..icon = icon
        ..gemType = gemType
        ..stacks = 1
        ..renderType = bf.RenderType.GRID;

  @override
  String name = "Leningrad";

  @override
  String description = "Each consecutive hit compounds the enemy's bounty.";

  @override
  String get subDescription =>
      "+${bountyPerStack.map((e) => "${(e * 100).toStringAsFixed(0)}%").join("/")} bounty per stack.";

  @override
  IconData icon = FontAwesomeIcons.moneyBillWave.data;

  @override
  CityType gemType = CityType.EEUROPE;
}

// Prague — Defenestration: each consecutive hit compounds armor shred.
class Defenestration extends Ability {
  Defenestration({required super.caster, required super.level});

  static const armorPerStack = [1.0, 1.5, 2.0, 2.5, 3.0, 4.0];

  @override
  bool get worksOnEnemies => true;

  @override
  bf.Buff? get buff => bf.ArmorModify(
        caster: caster,
        level: level,
        modifier: armorPerStack.getByLevel(level),
        overrideBaseDuration: 3,
      )
        ..name = name
        ..icon = icon
        ..gemType = gemType
        ..stacks = 1
        ..renderType = bf.RenderType.GRID;

  @override
  String name = "Defenestration";

  @override
  String description = "Each consecutive hit compounds armor shred.";

  @override
  String get subDescription => "-${armorPerStack.join("/")} armor per stack.";

  @override
  IconData icon = FontAwesomeIcons.windowMaximize.data;

  @override
  CityType gemType = CityType.EEUROPE;
}

// Warsaw — Uprising: each consecutive hit compounds the enemy's vulnerability.
class Uprising extends Ability {
  Uprising({required super.caster, required super.level});

  static const vulnPerStack = [0.05, 0.06, 0.07, 0.08, 0.09, 0.10];

  @override
  bool get worksOnEnemies => true;

  @override
  bf.Buff? get buff => bf.ReceiveDamageMultiple(
        caster: caster,
        level: level,
        overrideMultiplier: vulnPerStack.getByLevel(level),
        overrideBaseDuration: 3,
      )
        ..name = name
        ..icon = icon
        ..gemType = gemType
        ..stacks = 1;

  @override
  String name = "Uprising";

  @override
  String description =
      "Each consecutive hit compounds the enemy's vulnerability.";

  @override
  String get subDescription =>
      "+${vulnPerStack.map((e) => "${(e * 100).toStringAsFixed(0)}%").join("/")} damage taken per stack.";

  @override
  IconData icon = FontAwesomeIcons.handFist.data;

  @override
  CityType gemType = CityType.EEUROPE;
}
