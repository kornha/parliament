part of 'weurope.dart';

// Western Europe — Socialism / "share the attack".
// Socialism (each attack is shared across multiple enemies) is the shared spine.
// Each tier adds its own twist on top.
// Ireland(Drunken Socialism: random share count) -> Spain(Tiki-taka bounce)
// -> Italy(Gladiator execute) -> Portugal(Age of Discovery: global range, weak)
// -> France(Revolution: more enemies = more damage) -> UK(Seat of the Empire).
// Belgium (Bureaucracy: whole board, slow) is a separate special.
Set<Ability> weurope_abilities(WEuropeSettings settings, int level,
        GemComponent caster, CityConfig config) =>
    switch (config) {
      ireland => {
          DrunkenSocialism(level: level, caster: caster),
        },
      spain => {
          Socialism(level: level, caster: caster),
          TikiTaka(
              level: level, caster: caster, range: settings.baseRange(level)),
        },
      italy => {
          Socialism(level: level, caster: caster),
          Gladiator(level: level, caster: caster),
        },
      portugal => {
          AgeOfDiscovery(level: level, caster: caster),
        },
      france => {
          Socialism(level: level, caster: caster),
          Revolution(level: level, caster: caster),
        },
      uk => {
          SeatOfTheEmpire(level: level, caster: caster),
        },
      _ => throw UnimplementedError(
          'Unknown ability for level $level and config $config'),
    };

// Applies/refreshes a self damage multiplier on the casting gem.
void _applyDamageMultiplier(GemComponent gem, Ability ability, double mult) {
  final cs = bf.CriticalStrike(
      caster: gem, level: ability.level, overrideDamageMultiplier: mult)
    ..name = ability.name
    ..icon = ability.icon
    ..gemType = ability.gemType;
  if (gem.buffs.contains(cs)) {
    for (final b in gem.buffs) {
      if (b == cs) {
        b.duration = cs.duration;
        (b as bf.CriticalStrike).overrideDamageMultiplier =
            cs.overrideDamageMultiplier;
      }
    }
  } else {
    gem.buffs.add(cs);
  }
}

// Shared spine: each attack is shared across multiple enemies (each takes the full hit).
class Socialism extends Ability {
  Socialism({
    required super.caster,
    required super.level,
    this.numTargets = const [2, 3, 4, 5, 6, 7],
  }) {
    // "Share the wealth": spreading the attack across many enemies costs damage,
    // so every shared hit lands softer (applied to self via worksOnSelf).
    buff = bf.DamageMultiple(
      caster: caster,
      level: level,
      multipliersPerLevel: damageMultiplePerLevel,
    )..name = "Socialism";
  }

  final List<int> numTargets;

  static const damageMultiplePerLevel = [0.5, 0.55, 0.6, 0.65, 0.7, 0.75];

  @override
  bool get worksOnSelf => true;

  @override
  String name = "Socialism";

  @override
  String description =
      "Shares each attack across multiple enemies — but each hit lands for reduced damage.";

  @override
  String get subDescription =>
      "${numTargets.join("/")} targets at "
      "${damageMultiplePerLevel.map((e) => "${(e * 100).round()}%").join("/")} damage.";

  @override
  IconData icon = FontAwesomeIcons.peopleGroup.data;

  @override
  bool get canAttack => false;

  @override
  GameComponent? onEnemyAttack(GemComponent gem, EnemyComponent primaryTarget,
      Set<GameComponent> targets) {
    final num = numTargets.getByLevel(level);
    int i = 1;
    for (var e in targets) {
      if (i > num) break;
      gem.fire(e as EnemyComponent);
      i++;
    }
    return null;
  }

  @override
  CityType gemType = CityType.WEUROPE;
}

// Ireland — Drunken Socialism: shares the attack across a RANDOM number of enemies.
class DrunkenSocialism extends Ability {
  DrunkenSocialism({required super.caster, required super.level});

  static const maxTargetsPerLevel = [3, 4, 5, 6, 7, 8];

  final Random _r = Random();

  @override
  String name = "Drunken Socialism";

  @override
  String description = "Shares each attack across a random number of enemies.";

  @override
  String get subDescription => "1–${maxTargetsPerLevel.join("/")} targets.";

  @override
  IconData icon = FontAwesomeIcons.beerMugEmpty.data;

  @override
  bool get canAttack => false;

  @override
  GameComponent? onEnemyAttack(GemComponent gem, EnemyComponent primaryTarget,
      Set<GameComponent> targets) {
    final max = maxTargetsPerLevel.getByLevel(level);
    final num = _r.nextInt(max) + 1;
    int i = 1;
    for (var e in targets) {
      if (i > num) break;
      gem.fire(e as EnemyComponent);
      i++;
    }
    return null;
  }

  @override
  CityType gemType = CityType.WEUROPE;
}

// Belgium (special) — Bureaucracy: attacks every enemy on the board, but very slowly.
class Bureaucracy extends Ability {
  Bureaucracy({required super.caster, required super.level});

  @override
  String name = "Bureaucracy";

  @override
  String description = "Attacks every enemy on the board, but very slowly.";

  @override
  String get subDescription => "Global range; very slow.";

  @override
  IconData icon = FontAwesomeIcons.stamp.data;

  @override
  bool get canAttack => false;

  @override
  GameComponent? onEnemyAttack(GemComponent gem, EnemyComponent primaryTarget,
      Set<GameComponent> targets) {
    for (var e in targets) {
      gem.fire(e as EnemyComponent);
    }
    return null;
  }

  @override
  CityType gemType = CityType.WEUROPE;
}

// Portugal — Age of Discovery: fires the whole board, but every hit lands weakly.
// The third "whole-board" tower (Portugal weak dmg, Belgium slow, UK full).
class AgeOfDiscovery extends Ability {
  AgeOfDiscovery({required super.caster, required super.level}) {
    // Reaching the entire map at once comes at the cost of damage.
    buff = bf.DamageMultiple(
      caster: caster,
      level: level,
      multipliersPerLevel: const [0.4, 0.45, 0.5, 0.55, 0.6, 0.65],
    )..name = "Age of Discovery";
  }

  @override
  bool get canAttack => false;

  @override
  bool get worksOnSelf => true;

  @override
  String name = "Age of Discovery";

  @override
  String description =
      "Charts the entire board, attacking every enemy at once — but each hit lands weakly.";

  @override
  String get subDescription => "Global range; reduced damage.";

  @override
  IconData icon = FontAwesomeIcons.compass.data;

  @override
  GameComponent? onEnemyAttack(GemComponent gem, EnemyComponent primaryTarget,
      Set<GameComponent> targets) {
    for (var e in targets) {
      gem.fire(e as EnemyComponent);
    }
    return null;
  }

  @override
  CityType gemType = CityType.WEUROPE;
}

// France — Revolution: the more enemies on the field, the more damage.
class Revolution extends Ability {
  Revolution({required super.caster, required super.level});

  static const perEnemy = [0.10, 0.13, 0.16, 0.19, 0.22, 0.25];

  @override
  GameComponent? onEnemyAttack(GemComponent gem, EnemyComponent primaryTarget,
      Set<GameComponent> targets) {
    final mult = 1.0 + targets.length * perEnemy.getByLevel(level);
    _applyDamageMultiplier(gem, this, mult);
    return null;
  }

  @override
  String name = "Revolution";

  @override
  String description = "The more enemies on the field, the more damage.";

  @override
  String get subDescription =>
      "+${perEnemy.map((e) => "${(e * 100).toStringAsFixed(0)}%").join("/")} damage per enemy.";

  @override
  IconData icon = FontAwesomeIcons.flag.data;

  @override
  CityType gemType = CityType.WEUROPE;
}

// Spain — Tiki-taka: attacks bounce between nearby enemies.
class TikiTaka extends Ability {
  TikiTaka({
    required super.caster,
    required super.level,
    required this.range,
  });

  final double range;

  @override
  String name = "Tiki-taka";

  @override
  String description = "Attacks bounce between nearby enemies.";

  @override
  String get subDescription =>
      "Bounces to ${bf.ChainAttack.bouncesPerLevel.getByLevel(level)} enemies.";

  @override
  bf.Buff? get buff => bf.ChainAttack(
        caster: caster,
        level: level,
        range: range,
      );

  @override
  bool get worksOnEnemies => true;

  @override
  IconData icon = FontAwesomeIcons.futbol.data;

  @override
  CityType gemType = CityType.WEUROPE;
}

// Italy — Gladiator: chance to execute a wounded enemy outright.
class Gladiator extends Ability {
  Gladiator({required super.caster, required super.level});

  static var chancePerLevel = [0.10, 0.13, 0.16, 0.19, 0.22, 0.25];
  static const executeThreshold = [0.10, 0.12, 0.14, 0.16, 0.18, 0.20];

  @override
  double? get baseChance => chancePerLevel.getByLevel(level);

  final Random _r = Random();

  @override
  String name = "Gladiator";

  @override
  String description = "Chance to execute a wounded enemy outright.";

  @override
  String get subDescription =>
      "${chancePerLevel.map((e) => "${(e * 100).toStringAsFixed(0)}%").join("/")} chance to execute below "
      "${executeThreshold.map((e) => "${(e * 100).toStringAsFixed(0)}%").join("/")} HP.";

  @override
  IconData icon = FontAwesomeIcons.khanda.data;

  @override
  GameComponent? onEnemyAttack(GemComponent gem, EnemyComponent primaryTarget,
      Set<GameComponent> targets) {
    if (_r.nextDouble() < (currentChance ?? 0) &&
        primaryTarget.life <=
            primaryTarget.maxLife * executeThreshold.getByLevel(level)) {
      // lethal blow that overcomes armor
      primaryTarget.receiveDamage(primaryTarget.maxLife * 100, {}, gem);
    }
    return null;
  }

  @override
  CityType gemType = CityType.WEUROPE;
}

// UK — Seat of the Empire: attacks all enemies (global range); ramps attack speed.
class SeatOfTheEmpire extends Ability {
  static const increasePerLevelDefault = [0.2, 0.3, 0.4, 0.5, 0.6];
  static const inactiveDelay = Duration(seconds: 1);

  SeatOfTheEmpire({
    required super.caster,
    required super.level,
    this.increasePerLevel = increasePerLevelDefault,
  });

  final List<double> increasePerLevel;

  var count = 0;
  var lastAttack = DateTime.timestamp();

  @override
  bool get worksOnSelf => true;

  @override
  bool get canAttack => false;

  @override
  onEnemyAttack(gem, primaryTarget, targets) {
    final diff = DateTime.timestamp().difference(lastAttack);
    if (diff > inactiveDelay) {
      count = 0;
    }
    count++;
    buff = bf.AttackSpeedMultiple(
        caster: caster,
        level: level,
        overrideDurationType: bf.DurationType.ATTACK,
        overrideMultiplier: 1 + count * increasePerLevel.getByLevel(level));
    for (var e in targets) {
      gem.fire(e as EnemyComponent);
    }
    lastAttack = DateTime.timestamp();
    return null;
  }

  @override
  String name = "Seat of the Empire";

  @override
  String description =
      "Attacks all units. Each subsequent attack on any target increases attack speed.";

  @override
  String get subDescription => "";

  @override
  IconData icon = Icons.all_out;

  @override
  CityType gemType = CityType.WEUROPE;
}
