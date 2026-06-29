part of 'africa.dart';

// Africa — "The Wild": no shared spine; each country IS its own African icon.
// Ghana(Juju) -> Ethiopia(Caffeination) -> DR Congo(Cobalt) ->
// Kenya(Stampede) -> Nigeria(Afrobeat) -> South Africa(Great White).
Set<Ability> africa_abilities(AfricaSettings settings, int level,
        GemComponent caster, CityConfig config) =>
    switch (config) {
      ghana => {Juju(level: level, caster: caster)},
      ethiopia => {Caffeination(level: level, caster: caster)},
      drCongo => {Cobalt(level: level, caster: caster)},
      kenya => {Stampede(level: level, caster: caster)},
      nigeria => {Afrobeat(level: level, caster: caster)},
      southAfrica => {GreatWhite(level: level, caster: caster)},
      _ => throw UnimplementedError(
          'Unknown ability for level $level and config $config'),
    };

// South Africa — Great White: each hit tears away a % of the enemy's CURRENT HP.
// Huge bites on fresh enemies, diminishing as they drop; it can't quite kill.
class GreatWhite extends Ability {
  GreatWhite({required super.caster, required super.level});

  static const pctPerLevel = [0.05, 0.06, 0.07, 0.08, 0.09, 0.10];

  @override
  GameComponent? onEnemyAttack(GemComponent gem, EnemyComponent primaryTarget,
      Set<GameComponent> targets) {
    final bite = primaryTarget.life * pctPerLevel.getByLevel(level);
    if (bite > 0) primaryTarget.receiveDamage(bite, {}, gem);
    return null;
  }

  @override
  String name = "Great White";

  @override
  String description =
      "Each hit tears away a percentage of the enemy's current health.";

  @override
  String get subDescription =>
      "${pctPerLevel.map((e) => "${(e * 100).toStringAsFixed(0)}%").join("/")} current HP per hit.";

  @override
  IconData icon = FontAwesomeIcons.fish.data;

  @override
  CityType gemType = CityType.AFRICA;
}

// Kenya — Stampede: a heavy, slow, piercing charge that tramples the line.
class Stampede extends Ability {
  Stampede({required super.caster, required super.level});

  @override
  bool get worksOnEnemies => true;

  @override
  bf.Buff? get buff => bf.StampedeBuff(caster: caster, level: level);

  @override
  String name = "Stampede";

  @override
  String description =
      "A piercing charge that tramples and slows the whole line.";

  @override
  String get subDescription =>
      "Pierces all enemies; ${bf.StampedeBuff.slowPerLevel.map((e) => "${(e * 100).toStringAsFixed(0)}%").join("/")} slow.";

  @override
  IconData icon = FontAwesomeIcons.hippo.data;

  @override
  CityType gemType = CityType.AFRICA;
}

// Ghana — Juju: chance to hex an enemy into a harmless critter.
class Juju extends Ability {
  Juju({required super.caster, required super.level});

  static var chancePerLevel = [0.10, 0.13, 0.16, 0.19, 0.22, 0.25];

  @override
  double? get baseChance => chancePerLevel.getByLevel(level);

  @override
  bool get worksOnEnemies => true;

  @override
  bf.Buff? get buff => Random().nextDouble() < (currentChance ?? 0)
      ? (bf.Hex(caster: caster, level: level)..gemType = gemType)
      : null;

  @override
  String name = "Juju";

  @override
  String description = "Chance to turn an enemy into a harmless critter.";

  @override
  String get subDescription =>
      "${chancePerLevel.map((e) => "${(e * 100).toStringAsFixed(0)}%").join("/")} chance to hex for "
      "${bf.Hex.durationPerLevel.join("/")}s.";

  @override
  IconData icon = FontAwesomeIcons.frog.data;

  @override
  CityType gemType = CityType.AFRICA;
}

// Nigeria — Afrobeat: a fast machine-gun whose tempo (attack speed) randomly
// re-rolls every 1.5s, with invisible fast projectiles and low damage.
class Afrobeat extends Ability {
  Afrobeat({required super.caster, required super.level}) {
    timer = Timer.periodic(const Duration(milliseconds: 1500), (_) => nextTempo());
  }

  late final Timer timer;
  static const tempoPerLevel = [1.6, 1.7, 1.8, 1.9, 2.0, 2.2];
  double _multiple = 1.0;

  void nextTempo() {
    final hi = tempoPerLevel.getByLevel(level);
    _multiple = (hi - 1 / hi) * Random().nextDouble() + 1 / hi;
  }

  @override
  void onGemDestroyed(GemComponent gem) {
    timer.cancel();
    super.onGemDestroyed(gem);
  }

  @override
  GameComponent? onEnemyAttack(GemComponent gem, EnemyComponent primaryTarget,
      Set<GameComponent> targets) {
    gem.buffs.add(bf.AttackSpeedMultiple(
      caster: caster,
      level: level,
      overrideMultiplier: _multiple,
      overrideDurationType: bf.DurationType.ATTACK,
    )
      ..name = name
      ..gemType = gemType);
    return null;
  }

  @override
  String name = "Afrobeat";

  @override
  String description =
      "A fast, fluctuating drumbeat of attacks (random tempo, low damage).";

  @override
  String get subDescription =>
      "Random tempo up to ${tempoPerLevel.map((e) => "${e}x").join("/")}.";

  @override
  IconData icon = FontAwesomeIcons.drum.data;

  @override
  CityType gemType = CityType.AFRICA;
}

// DR Congo — Cobalt: a no-attack electrocution aura that damages all nearby
// enemies but the jolt SPEEDS THEM UP.
class Cobalt extends Ability {
  Cobalt({required super.caster, required super.level});

  @override
  bool get canAttack => false;

  @override
  bool get enemiesAura => true;

  @override
  bf.Buff? get buff => bf.CobaltBuff(caster: caster, level: level);

  @override
  String name = "Cobalt";

  @override
  String description =
      "Electrocutes all nearby enemies — but the jolt speeds them up.";

  @override
  String get subDescription =>
      "${bf.CobaltBuff.damagePerLevel.join("/")} dmg/s; speeds enemies up.";

  @override
  IconData icon = FontAwesomeIcons.bolt.data;

  @override
  CityType gemType = CityType.AFRICA;
}

// Ethiopia — Caffeination: coffee burst-then-crash (birthplace of coffee). The
// first few attacks on an enemy fire at a big attack-speed surge, then the
// tower crashes to the inverse speed for the rest of the engagement.
// Local Africa implementation (distinct from the shared N. America one) so it
// carries CityType.AFRICA and lives in this region's files.
class Caffeination extends Ability {
  Caffeination({required super.caster, required super.level});

  static const increasePerLevel = [2.3, 2.6, 2.9, 3.2, 3.5, 3.8];

  int count = 0;
  late int numberOfAttacks = level + 1;

  @override
  GameComponent? onEnemyAttack(GemComponent gem, EnemyComponent primaryTarget,
      Set<GameComponent> targets) {
    if (gem.lastEnemy != primaryTarget) {
      count = 0;
    }
    final surge = increasePerLevel.getByLevel(level);
    if (count < numberOfAttacks - 1) {
      // Burst: ride the surge for the opening attacks.
      count++;
      gem.buffs.add(bf.AttackSpeedMultiple(
        caster: caster,
        level: level,
        overrideDurationType: bf.DurationType.ATTACK,
        overrideMultiplier: surge,
      )
        ..name = name
        ..gemType = gemType);
    } else {
      // Crash: slump to the inverse of the surge once the buzz wears off.
      gem.buffs.add(bf.AttackSpeedMultiple(
        caster: caster,
        level: level,
        overrideDurationType: bf.DurationType.ATTACK,
        overrideMultiplier: 1 / surge,
      )
        ..name = name
        ..gemType = gemType);
    }
    return null;
  }

  @override
  String name = "Caffeination";

  @override
  String description =
      "A coffee rush: a burst of fast attacks, then a sluggish crash.";

  @override
  String get subDescription =>
      "First $numberOfAttacks attacks at ${increasePerLevel.join("/")}x speed, "
      "then ${increasePerLevel.map((e) => "1/$e").join("/")}x speed.";

  @override
  IconData icon = Icons.coffee;

  @override
  CityType gemType = CityType.AFRICA;
}
