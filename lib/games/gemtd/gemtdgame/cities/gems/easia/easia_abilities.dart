part of 'easia.dart';

// East Asia — Fortune / chance-to-stun.
// Fortune (every tower has a chance to stun on hit) is the shared spine. The
// region's identity is manipulating those odds: guarantee them (Taiwan),
// multiply them (China). K-Pop/Kaizen sit off the spine.
// Mongolia(Khan: the bare chance-to-stun) -> Taiwan(Semiconductor: all chance
// abilities proc 100%) -> Hong Kong(Already Tomorrow: every attack strikes twice)
// -> South Korea(K-Pop: armor down + speeds enemy up) -> Japan(Kaizen: permanent
// damage per kill) -> China(People's Republic: aura multiplies proc chance).
Set<Ability> easia_abilities(EAsiaSettings settings, int level,
        GemComponent caster, CityConfig config) =>
    switch (config) {
      mongolia => {
          Khan(level: level, caster: caster),
          GoldenHorde(level: level, caster: caster),
        },
      taiwan => {
          Khan(level: level, caster: caster),
          Semiconductor(level: level, caster: caster),
        },
      hongKong => {
          Khan(level: level, caster: caster),
          AlreadyTomorrow(level: level, caster: caster),
        },
      sKorea => {
          Khan(level: level, caster: caster),
          KPop(level: level, caster: caster),
        },
      japan => {
          Khan(level: level, caster: caster),
          Kaizen(level: level, caster: caster),
        },
      china => {
          Khan(level: level, caster: caster),
          PeoplesRepublic(level: level, caster: caster),
        },
      _ => throw UnimplementedError(
          'Unknown ability for level $level and config $config'),
    };

// Shared spine: Khan — every hit has a chance to stun the enemy (Fortune).
class Khan extends Ability {
  Khan({required super.caster, required super.level});

  static var chancePerLevel = [0.25, 0.28, 0.31, 0.34, 0.37, 0.40];

  @override
  bool get worksOnEnemies => true;

  @override
  double? get baseChance => chancePerLevel.getByLevel(level);

  @override
  bf.Buff? get buff => Random().nextDouble() < currentChance!
      ? bf.Stun(caster: caster, level: level)
      : null;

  @override
  String name = "Khan";

  @override
  String description = "Stuns an enemy.";

  @override
  String get subDescription => "${currentChance} chance to stun for\n"
      "${bf.Stun.durationPerLevel.join("/")} seconds.";

  @override
  IconData icon = FontAwesomeIcons.yinYang.data;

  @override
  CityType gemType = CityType.EASIA;
}

// Mongolia — Golden Horde: the horde rides wide — chance to loose an arrow
// at a second enemy alongside the primary attack.
class GoldenHorde extends Ability {
  GoldenHorde({required super.caster, required super.level});

  static var chancePerLevel = [0.20, 0.24, 0.28, 0.32, 0.36, 0.40];

  @override
  double? get baseChance => chancePerLevel.getByLevel(level);

  @override
  String name = "Golden Horde";

  @override
  String description = "Chance to attack a second enemy.";

  @override
  String get subDescription =>
      "${chancePerLevel.map((e) => "${(e * 100).toStringAsFixed(0)}%").join("/")} chance to strike a second target.";

  @override
  bool get canAttack => false;

  @override
  IconData icon = FontAwesomeIcons.horse.data;

  @override
  CityType gemType = CityType.EASIA;

  @override
  GameComponent? onEnemyAttack(GemComponent gem, EnemyComponent primaryTarget,
      Set<GameComponent> targets) {
    gem.fire(primaryTarget);
    if (Random().nextDouble() < currentChance!) {
      final second = targets.firstWhere(
          (t) => t != primaryTarget && t is EnemyComponent,
          orElse: () => primaryTarget);
      if (second != primaryTarget) {
        gem.fire(second as EnemyComponent);
      }
    }
    return null;
  }
}

// Taiwan — Semiconductor: causes all of this tower's chance abilities to cast
// 100% of the time. Nothing else.
class Semiconductor extends Ability {
  Semiconductor({required super.caster, required super.level});

  @override
  String name = "Semiconductor";

  @override
  String description =
      "Causes all of this tower's chance abilities to cast 100% of the time.";

  @override
  String get subDescription => "All chance abilities proc at 100%.";

  @override
  bool get worksOnSelf => true;

  @override
  bf.Buff? get buff => SemiconductorBuff(caster: caster, level: level);

  @override
  IconData icon = Icons.copy_all;

  @override
  CityType gemType = CityType.EASIA;
}

// Forces every chance-based ability on the caster to proc 100% of the time —
// and nothing else (no damage / attack-speed / duration changes).
class SemiconductorBuff extends bf.Buff {
  SemiconductorBuff({required super.caster, required super.level});

  @override
  String name = "Semiconductor";

  @override
  String description = "Causes all chance abilities to cast 100% of the time.";

  @override
  IconData icon = Icons.copy_all;

  @override
  CityType gemType = CityType.EASIA;

  @override
  double? baseDuration = 1.0;

  @override
  double? get chanceMultiplier => 100.0;
}

// Hong Kong — Already Tomorrow: every attack strikes twice.
class AlreadyTomorrow extends SequentialAttack {
  AlreadyTomorrow({required super.caster, required super.level});

  @override
  String name = "Already Tomorrow";

  @override
  String description = "Every attack strikes twice.";

  @override
  CityType gemType = CityType.EASIA;

  @override
  bf.SequentialAttack createBuff() => bf.SequentialAttack(
        caster: caster,
        level: level,
        attacksNumPerLevel: const [2, 2, 2, 2, 2, 2],
      );
}

// South Korea — K-Pop (reworked): idol-grade tempo. Drastically increased
// attack speed and every chance ability procs 100%, but each hit is weak and
// debuffs are short — with the Khan spine this reads as a stream of ministuns.
class KPop extends Ability {
  KPop({required super.caster, required super.level});

  @override
  String name = "K-Pop";

  @override
  String description =
      "Idol-grade tempo: attacks drastically faster and every chance ability "
      "procs 100% of the time, but hits are weak and debuffs are short — a "
      "stream of ministuns.";

  @override
  String get subDescription =>
      "${KPopBuff.fraction.join("/")}x attack speed, damage divided by "
      "the same.\n"
      "All chance abilities proc 100%; debuff durations reduced 75%.";

  @override
  bool get worksOnSelf => true;

  @override
  bf.Buff? get buff => KPopBuff(caster: caster, level: level);

  @override
  IconData icon = FontAwesomeIcons.music.data;

  @override
  CityType gemType = CityType.EASIA;
}

// The self-buff behind K-Pop: speed for damage, certainty for duration.
class KPopBuff extends bf.Buff {
  KPopBuff({required super.caster, required super.level});

  static const fraction = <double>[6.0, 6.5, 7.0, 7.5, 8.0, 8.5];

  @override
  String name = "K-Pop";

  @override
  String description =
      "Attacking drastically faster with weak hits; all chance abilities "
      "proc, debuffs are short.";

  @override
  IconData icon = FontAwesomeIcons.music.data;

  @override
  CityType gemType = CityType.EASIA;

  @override
  double? get attackSpeedMultiplier => fraction.getByLevel(level);

  @override
  double? get damageMultiplier => 1 / fraction.getByLevel(level);

  @override
  double? get chanceMultiplier => 100.0;

  @override
  double? get buffMultiplier => 0.25;

  @override
  double? baseDuration = 1.0;

  @override
  bf.RenderType get renderType => bf.RenderType.NONE;
}

// Japan — Kaizen: permanent damage gain per bounty (continuous improvement).
class Kaizen extends Ability {
  Kaizen({required super.caster, required super.level});

  @override
  String name = "Kaizen";

  @override
  String description = "Each bounty yields more experience.";

  @override
  String get subDescription =>
      "${bf.BountyMultiple.defaultMultipliers.join("/")}x per bounty.";

  @override
  bf.Buff? get buff => bf.BountyMultiple(
        caster: caster,
        level: level,
        overrideBaseDuration: null, // need to set null here or will expire
      );

  @override
  bool get worksOnSelf => true;

  @override
  CityType gemType = CityType.EASIA;

  @override
  IconData icon = FontAwesomeIcons.angleUp.data;
}

// China — People's Republic: aura that multiplies the proc chance of all
// chance-based abilities for nearby allies (the Fortune capstone).
class PeoplesRepublic extends Ability {
  // THIS ABILITY CAN ONLY EXIST FOR ONE LEVEL UNTIL WE UPDATE
  // STACKTYPE.BUFF

  PeoplesRepublic({required super.caster, required super.level});

  @override
  String name = "The People's Republic";

  @override
  bool get alliesAura => true;

  @override
  String description =
      "Multiplies odds all chance based abilities for cities in the area by 8x."
      "\nReduces the buffs of all cities in the area by 75%.";

  @override
  bf.Buff? get buff => bf.PeoplesRepublic(caster: caster, level: level);

  @override
  String get subDescription => "";

  @override
  CityType gemType = CityType.EASIA;

  @override
  IconData icon = FontAwesomeIcons.personMilitaryToPerson.data;
}
