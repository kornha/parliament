part of 'namerica.dart';

// North America — Capitalism (RNG damage swings) is the shared spine on every
// tower. Each tier adds its own twist.
// Cuba(Viva la Revolución) -> Jamaica(Feel Good Man) -> Panama(Tax Haven: spine
// only) -> Canada(Immigration) -> Mexico(Cartel) -> USA(Deep State: capstone).
Set<Ability> namerica_abilities(NAmericaSettings settings, int level,
        GemComponent caster, CityConfig config) =>
    switch (config) {
      cuba => {
          Capitalism(level: level, caster: caster),
          VivaLaRevolucion(level: level, caster: caster),
        },
      jamaica => {
          Capitalism(level: level, caster: caster),
          FeelGoodMan(level: level, caster: caster),
        },
      panama => {
          Capitalism(level: level, caster: caster),
        },
      canada => {
          Capitalism(level: level, caster: caster),
          Immigration(level: level, caster: caster),
        },
      mexico => {
          Capitalism(level: level, caster: caster),
          Cartel(level: level, caster: caster),
        },
      usa => {
          Capitalism(level: level, caster: caster),
          DeepState(level: level, caster: caster),
        },
      _ => throw UnimplementedError(
          'Unknown ability for level $level and config $config'),
    };

// Cuba — Viva la Revolución: a cheap, weak tower whose shots ricochet through
// the line. It deals reduced damage (see settings) and the enemies it tags are
// worth less capital, but every attack bounces between them.
class VivaLaRevolucion extends Ability {
  VivaLaRevolucion({required super.caster, required super.level});

  // Bounty the struck enemies pay out (a penalty < 100%).
  static const bountyPenaltyPerLevel = [0.6, 0.65, 0.7, 0.75, 0.8, 0.85];

  @override
  bool get worksOnEnemies => true;

  // The bounce — collected into the bullet via getFiringBuffs.
  @override
  bf.Buff? get buff => bf.ChainAttack(
        caster: caster,
        level: level,
        range: 2.5,
      )
        ..name = name
        ..icon = icon
        ..gemType = gemType;

  // Tag each struck enemy so it yields reduced capital when killed.
  @override
  GameComponent? onEnemyAttack(GemComponent gem, EnemyComponent primaryTarget,
      Set<GameComponent> targets) {
    primaryTarget.buffs.add(bf.BountyMultiple(
      caster: caster,
      level: level,
      overrideMultiplier: bountyPenaltyPerLevel.getByLevel(level),
      overrideBaseDuration: 4,
    )
      ..name = name
      ..icon = icon
      ..gemType = gemType);
    return null;
  }

  @override
  String name = "Viva la Revolución";

  @override
  String description =
      "Attacks bounce between enemies, but this tower deals reduced damage and "
      "the enemies it tags are worth less capital.";

  @override
  String get subDescription =>
      "Bounces to ${bf.ChainAttack.bouncesPerLevel.getByLevel(level)} enemies; "
      "tagged enemies pay ${bountyPenaltyPerLevel.map((e) => "${(e * 100).toStringAsFixed(0)}%").join("/")} capital.";

  @override
  IconData icon = FontAwesomeIcons.recycle.data;

  @override
  CityType gemType = CityType.NAMERICA;
}

// Jamaica — Feel Good Man: a laid-back aura. Nearby enemies are slowed, and
// nearby allied towers attack more slowly too (everybody just chills).
class FeelGoodMan extends Ability {
  FeelGoodMan({required super.caster, required super.level});

  static const enemySlowPerLevel = [0.15, 0.18, 0.21, 0.24, 0.27, 0.30];
  // Attack-speed multiplier applied to nearby allies (< 1 = slower).
  static const allySlowPerLevel = [0.9, 0.88, 0.86, 0.84, 0.82, 0.8];

  @override
  bool get enemiesAura => true;

  // The enemy slow (applied to all enemies in range via the base aura logic).
  @override
  bf.Buff? get buff => bf.SpeedModify(
        caster: caster,
        level: level,
        modifier: enemySlowPerLevel.getByLevel(level),
        overrideBaseDuration: 1.5,
      )
        ..name = name
        ..icon = icon
        ..gemType = gemType
        ..renderType = bf.RenderType.GRID;

  // Allies in range get a relaxed (slower) attack speed.
  @override
  void onAuraScan(Set<GemComponent> gems) {
    for (final g in gems) {
      if (g == caster || g.gemType == CityType.ROCK) continue;
      final chill = bf.AttackSpeedMultiple(
        caster: caster,
        level: level,
        overrideMultiplier: allySlowPerLevel.getByLevel(level),
      )
        ..name = name
        ..icon = icon
        ..gemType = gemType;
      if (g.buffs.contains(chill)) {
        for (final b in g.buffs) {
          if (b == chill) b.duration = chill.duration;
        }
      } else {
        g.buffs.add(chill);
      }
    }
  }

  @override
  String name = "Feel Good Man";

  @override
  String description =
      "Chills the area: nearby enemies are slowed and nearby allied towers "
      "attack more slowly.";

  @override
  String get subDescription =>
      "${enemySlowPerLevel.map((e) => "${(e * 100).toStringAsFixed(0)}%").join("/")} enemy slow; "
      "allies attack at ${allySlowPerLevel.map((e) => "${(e * 100).toStringAsFixed(0)}%").join("/")} speed.";

  @override
  IconData icon = Icons.self_improvement;

  @override
  CityType gemType = CityType.NAMERICA;
}

// USA — Deep State: the capstone. Invisible shots strike a random target across
// a vastly extended range (projectile/explosion go invisible in settings);
// paired with the Capitalism spine for wildly unpredictable damage.
class DeepState extends FullMoon {
  DeepState({required super.caster, required super.level});

  @override
  String name = "Deep State";

  @override
  String description =
      "Strikes a random target across the whole board with unpredictable force.";

  @override
  IconData icon = FontAwesomeIcons.userSecret.data;

  @override
  CityType gemType = CityType.NAMERICA;
}
