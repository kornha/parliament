part of 'samerica.dart';

// South America — Burn (DoT) / the rainforest's on-fire region.
// Burn (damage over time) is the shared spine.
// Peru(Inti — pure Burn spine) -> Chile(Inferno — burn aura, cannot attack)
// -> Colombia(Cocaine — extreme caffeination: huge attack-speed burst then a
// hard crash) -> Venezuela(Crude — oil that amplifies damage taken, no slow)
// -> Argentina(Tango — pulls enemies together, no slow)
// -> Brazil(Redeemer — chance a leaked enemy costs no capital, capstone).
Set<Ability> samerica_abilities(SAmericaSettings settings, int level,
        GemComponent caster, CityConfig config) =>
    switch (config) {
      // Peru — Inti (Sun): the pure Burn DoT spine. Reuse the shared Burn
      // ability, surfaced under the country's own name.
      peru => {
          Burn(level: level, caster: caster)
            ..name = "Inti"
            ..description = "Sets enemies ablaze, damaging them over time."
            ..icon = FontAwesomeIcons.sun.data,
        },
      // Chile — Inferno: a blazing burn aura (Chilean wildfires); cannot attack.
      chile => {
          Inferno(level: level, caster: caster),
        },
      // Colombia — Cocaine: extreme caffeination — a huge upfront attack-speed
      // burst followed by a hard crash.
      colombia => {
          Burn(level: level, caster: caster),
          Cocaine(level: level, caster: caster),
        },
      // Venezuela — Crude: oil that only amplifies the damage enemies take
      // (no slow) — combos with the Burn spine.
      venezuela => {
          Burn(level: level, caster: caster),
          Crude(level: level, caster: caster),
        },
      // Argentina — Tango: pulls enemies together (no slow).
      argentina => {
          Burn(level: level, caster: caster),
          Tango(level: level, caster: caster),
        },
      // Brazil — Redeemer: chance a leaked enemy costs no capital (capstone).
      brazil => {
          Burn(level: level, caster: caster),
          Redeemer(level: level, caster: caster),
        },
      _ => throw UnimplementedError(
          'Unknown ability for level $level and config $config'),
    };

// Colombia — Cocaine: extreme caffeination. The first few attacks on a target
// land at a massive attack-speed multiplier; once the burst is spent every
// subsequent attack is heavily slowed (the crash). Stronger numbers than
// N. America's Caffeination.
class Cocaine extends Ability {
  Cocaine({required super.caster, required super.level});

  static const increasePerLevel = [3.0, 3.4, 3.8, 4.2, 4.6, 5.0];

  int count = 0;
  late int numberOfAttacks = level + 2;

  @override
  String name = "Cocaine";

  @override
  String description =
      "A huge upfront attack-speed burst, then a hard crash in attack speed.";

  @override
  String get subDescription =>
      "First $numberOfAttacks attacks at ${increasePerLevel.map((e) => "${e.toStringAsFixed(1)}x").join("/")} speed.\n"
      "Then crashes to ${increasePerLevel.map((e) => "1/${e.toStringAsFixed(1)}x").join("/")} speed.";

  @override
  GameComponent? onEnemyAttack(GemComponent gem, EnemyComponent primaryTarget,
      Set<GameComponent> targets) {
    if (gem.lastEnemy != primaryTarget) {
      count = 0;
    }
    final mult = increasePerLevel.getByLevel(level);
    if (count < numberOfAttacks - 1) {
      count++;
      gem.buffs.add(bf.AttackSpeedMultiple(
        caster: caster,
        level: level,
        overrideDurationType: bf.DurationType.ATTACK,
        overrideMultiplier: mult,
      ));
    } else {
      gem.buffs.add(bf.AttackSpeedMultiple(
        caster: caster,
        level: level,
        overrideDurationType: bf.DurationType.ATTACK,
        overrideMultiplier: 1 / mult,
      ));
    }
    return null;
  }

  @override
  IconData icon = FontAwesomeIcons.snowflake.data;

  @override
  CityType gemType = CityType.SAMERICA;
}

// Venezuela — Crude: oil that ONLY amplifies the damage enemies take (no slow).
// Distinct from MENA's Black Gold (which slows) and synergizes with the Burn
// spine. Uses ReceiveDamageMultiple alone — no SpeedModify.
class Crude extends Ability {
  Crude({required super.caster, required super.level});

  static const dmgAmpPerLevel = <double>[0.15, 0.20, 0.25, 0.30, 0.35, 0.40];

  @override
  bool get worksOnEnemies => true;

  @override
  bf.Buff? get buff => bf.ReceiveDamageMultiple(
        caster: caster,
        level: level,
        overrideMultiplier: dmgAmpPerLevel.getByLevel(level),
        overrideBaseDuration: 3,
      )
        ..name = name
        ..icon = icon
        ..gemType = gemType;

  @override
  String name = "Crude";

  @override
  String description =
      "Coats enemies in oil, amplifying the damage they take.";

  @override
  String get subDescription =>
      "${dmgAmpPerLevel.map((e) => "${(e * 100).toStringAsFixed(0)}%").join("/")} amplified damage.";

  @override
  IconData icon = Icons.oil_barrel;

  @override
  CityType gemType = CityType.SAMERICA;
}

// Argentina — Tango: pulls nearby enemies together toward the struck enemy.
// No slow — pure clustering.
class Tango extends Ability {
  Tango({required super.caster, required super.level});

  // How strongly (as a fraction of the gap) enemies are drawn toward the
  // primary target each attack, and the radius (in grid units) it affects.
  static const pullStrengthPerLevel = [0.12, 0.16, 0.20, 0.24, 0.28, 0.34];
  static const radiusPerLevel = [2.0, 2.25, 2.5, 2.75, 3.0, 3.5];

  @override
  bool get worksOnEnemies => true;

  @override
  GameComponent? onEnemyAttack(GemComponent gem, EnemyComponent primaryTarget,
      Set<GameComponent> targets) {
    final strength = pullStrengthPerLevel.getByLevel(level);
    final radiusSq = pow(radiusPerLevel.getByLevel(level), 2).toDouble();
    final anchor = primaryTarget.position;
    for (final target in targets) {
      if (target == primaryTarget) continue;
      if (target is! EnemyComponent) continue;
      if (target.position.distanceToSquared(anchor) > radiusSq) continue;
      // Draw the enemy a fraction of the way toward the struck enemy.
      target.position
          .add((anchor - target.position).scaled(strength.toDouble()));
    }
    return null;
  }

  @override
  String name = "Tango";

  @override
  String description = "Draws nearby enemies together toward the target.";

  @override
  String get subDescription =>
      "Pulls enemies within ${radiusPerLevel.map((e) => e.toStringAsFixed(1)).join("/")} tiles together.";

  @override
  IconData icon = FontAwesomeIcons.personDress.data;

  @override
  CityType gemType = CityType.SAMERICA;
}
