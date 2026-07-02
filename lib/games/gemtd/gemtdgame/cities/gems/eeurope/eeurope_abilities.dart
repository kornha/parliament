part of 'eeurope.dart';

// Eastern Europe — Oligarchy / compounding.
// Oligarchy (each consecutive hit on the same enemy compounds attack speed) is
// the shared spine on every tower. Each tier adds its own twist.
// Latvia(spine only) -> Hungary(Thermal Baths: compound slow)
// -> Czechia(Defenestration: compound armor shred) -> Ukraine(Wheat & Sky: gold/attack)
// -> Poland(Uprising: compound vulnerability) -> Russia(Mother Russia: resets only on kill).
Set<Ability> eeurope_abilities(EEuropeSettings settings, int level,
        GemComponent caster, CityConfig config) =>
    switch (config) {
      latvia => {
          Oligarchy(level: level, caster: caster),
        },
      hungary => {
          Oligarchy(level: level, caster: caster),
          ThermalBaths(level: level, caster: caster),
        },
      czechia => {
          Oligarchy(level: level, caster: caster),
          Defenestration(level: level, caster: caster),
        },
      ukraine => {
          Oligarchy(level: level, caster: caster),
          WheatAndSky(level: level, caster: caster),
        },
      poland => {
          Oligarchy(level: level, caster: caster),
          Uprising(level: level, caster: caster),
        },
      russia => {
          MotherRussia(level: level, caster: caster),
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
    this.resetOnKillOnly = false,
  });

  static const increasePerLevel = [0.15, 0.2, 0.25, 0.3, 0.35, 0.4];
  static const _max = 50;

  final bool neverResets;
  // Mother Russia: persists across target-switches, resets only when it kills.
  final bool resetOnKillOnly;
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
    if (resetOnKillOnly) {
      // Reset only when the previous target died (a kill); persist otherwise.
      if (caster.lastEnemy != null &&
          caster.lastEnemy != primaryTarget &&
          (caster.lastEnemy?.dead ?? false)) {
        count = 0;
      }
      if (count < _max) count++;
    } else if (neverResets || caster.lastEnemy == primaryTarget) {
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

// Russia — Mother Russia: the compounding attack speed only resets on a kill.
class MotherRussia extends Oligarchy {
  MotherRussia({required super.caster, required super.level})
      : super(resetOnKillOnly: true);

  @override
  String name = "Mother Russia";

  @override
  String description =
      "Compounding attack speed that only resets when it gets a kill.";

  @override
  IconData icon = FontAwesomeIcons.chessRook.data;
}

// Ukraine — Wheat & Sky: a small flat amount of gold on every attack (Europe's
// breadbasket). Doesn't compound; just scales with how fast it fires.
class WheatAndSky extends Ability {
  WheatAndSky({required super.caster, required super.level});

  static const goldPerLevel = [0.2, 0.25, 0.3, 0.35, 0.4, 0.5];

  @override
  GameComponent? onEnemyAttack(GemComponent gem, EnemyComponent primaryTarget,
      Set<GameComponent> targets) {
    gem.gameRef.gameStats.capital += goldPerLevel.getByLevel(level);
    return null;
  }

  @override
  String name = "Wheat & Sky";

  @override
  String description = "Generates a little gold with every attack.";

  @override
  String get subDescription => "+${goldPerLevel.join("/")} gold per attack.";

  @override
  IconData icon = Icons.attach_money;

  @override
  CityType gemType = CityType.EEUROPE;
}

// Hungary — Thermal Baths: each consecutive hit compounds a slow.
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
        ..maxStacks = 8
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

// Czechia — Defenestration: each consecutive hit compounds armor shred.
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
        ..maxStacks = 12
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

// Poland — Uprising: each consecutive hit compounds the enemy's vulnerability.
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
        ..stacks = 1
        ..maxStacks = 10;

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
