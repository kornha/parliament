part of 'africa.dart';

// Africa — "The Wild": each city IS an animal/icon; there is no shared ability.
// Addis Ababa(Vultures) -> Kinshasa(Cobalt) -> Lagos(Afrobeat) ->
// Johannesburg(Hex) -> Nairobi(Stampede) -> Cape Town(Great White).
Set<Ability> africa_abilities(AfricaSettings settings, int level,
        GemComponent caster, CityConfig config) =>
    switch (config) {
      addis_ababa => {Vultures(level: level, caster: caster)},
      kinshasa => {Cobalt(level: level, caster: caster)},
      lagos => {Afrobeat(level: level, caster: caster)},
      johannesburg => {AfricanHex(level: level, caster: caster)},
      nairobi => {Stampede(level: level, caster: caster)},
      cape_town => {GreatWhite(level: level, caster: caster)},
      _ => throw UnimplementedError(
          'Unknown ability for level $level and config $config'),
    };

// Cape Town — Great White: each hit tears away a % of the enemy's CURRENT HP.
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

// Nairobi — Stampede: a heavy, slow, piercing charge that tramples the line.
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

// Johannesburg — Hex: chance to turn an enemy into a harmless critter.
class AfricanHex extends Ability {
  AfricanHex({required super.caster, required super.level});

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
  String name = "Hex";

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

// Lagos — Afrobeat: a fast machine-gun whose tempo (attack speed) randomly
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

// Kinshasa — Cobalt: a no-attack electrocution aura that damages all nearby
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

// Addis Ababa — Vultures: birds that orbit the tower, damaging enemies they
// pass through (spawns OrbitComponents on build; cleaned up on destroy/convert).
class Vultures extends Ability {
  Vultures({required super.caster, required super.level});

  static const countPerLevel = [2, 2, 3, 3, 4, 4];

  final List<OrbitComponent> _birds = [];

  @override
  bool get canAttack => false;

  @override
  void onGemBuilt(GemComponent gem) {
    final n = countPerLevel.getByLevel(level);
    for (int i = 0; i < n; i++) {
      final bird = OrbitComponent(
        gem: gem,
        orbitRadius: gem.radarRange,
        angularSpeed: 2.5,
        startAngle: (2 * pi / n) * i,
        size: gem.size * 0.4,
      );
      _birds.add(bird);
      gem.parent?.add(bird);
    }
  }

  void _clear() {
    for (final b in _birds) {
      b.removeFromParent();
    }
    _birds.clear();
  }

  @override
  void onGemDestroyed(GemComponent gem) {
    _clear();
    super.onGemDestroyed(gem);
  }

  @override
  void onGemConverted(GemComponent gem) {
    _clear();
    super.onGemConverted(gem);
  }

  @override
  String name = "Vultures";

  @override
  String description =
      "Birds circle the tower, damaging enemies they pass through.";

  @override
  String get subDescription =>
      "${countPerLevel.getByLevel(level)} circling birds.";

  @override
  IconData icon = FontAwesomeIcons.crow.data;

  @override
  CityType gemType = CityType.AFRICA;
}
