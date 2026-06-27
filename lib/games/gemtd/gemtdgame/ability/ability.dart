import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:political_think/games/gemtd/common/extensions.dart';
import 'package:political_think/games/gemtd/gemtdgame/ability/buff.dart' as bf;
import 'package:political_think/games/gemtd/gemtdgame/base/game_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gem_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/enemy/enemy_component.dart';
import 'package:quiver/core.dart';

abstract class Ability {
  abstract String name;
  abstract String description;

  String get subDescription;

  abstract IconData icon;
  abstract CityType gemType;

  Color get color => gemType.color();

  GemComponent caster;
  int level;

  // EnemyComponent? lastEnemy;

  Ability({required this.caster, required this.level});

  // abilities with buffs
  bf.Buff? buff;

  // exposable vars
  bool canAttack = true;

  // ability->buff override ability model
  double? baseChance;
  late double? _chance = baseChance;

  double? get currentChance => _chance;

  set currentChance(double? chance) {
    _chance = chance;
  }

  //
  bool worksOnSelf = false;
  bool alliesAura = false;
  bool worksOnEnemies = false;
  bool enemiesAura = false;

  // aura for enemies, named as such because its called onEnemyAttack
  GameComponent? onEnemyAttack(GemComponent gem, EnemyComponent primaryTarget,
      Set<GameComponent> targets) {
    if (enemiesAura) {
      targets.forEach((enemy) {
        if (enemy is EnemyComponent) {
          enemy.buffs.add(buff!);
        }
      });
      return null;
    }
  }

  // Only for allies aura, Use onEnemyAttack for enemy aura
  // final Set<GemComponent> _gems = {};
  void onAuraScan(Set<GemComponent> gems) {
    if (worksOnSelf) {
      if (buff?.caster.buffs.contains(buff!) ?? false) {
        var bf = buff!.caster.buffs.firstWhere((element) => element == buff);
        bf.duration = buff!.duration;
      } else {
        buff?.caster.buffs.add(buff!);
      }
    }
    if (alliesAura) {
      gems.forEach((gem) {
        if (gem.buffs.contains(buff!)) {
          var bf = gem.buffs.firstWhere((element) => element == buff);
          bf.duration = buff!.duration;
        } else {
          gem.buffs.add(buff!);
        }
      });
      // gems.forEach((element) {
      //   if (!_gems.contains(element)) {
      //     _gems.add(element);
      //     element.buffs.add(buff!);
      //   }
      // });

      // _gems.removeWhere((gem) {
      //   if (!gems.contains(gem)) {
      //     gem.buffs.remove(buff!);
      //     return true;
      //   }
      //   return false;
      // });
    }
  }

  GemComponent? _gem;

  void onGemBuilt(GemComponent gem) {}

  void onGemConverted(GemComponent gem) {
    // if (worksOnAllies) {
    //   _gems.forEach((element) {
    //     element.buffs.remove(buff!);
    //   });
    //   _gems.clear();
    // }
    if (worksOnSelf) {
      _gem?.buffs.remove(buff!);
      _gem = null;
    }
  }

  void onGemDestroyed(GemComponent gem) {
    // if (worksOnAllies) {
    //   _gems.forEach((element) {
    //     element.buffs.remove(buff!);
    //   });
    //   _gems.clear();
    // }
    if (worksOnSelf) {
      _gem?.buffs.remove(buff!);
      _gem = null;
    }
  }

  @override
  bool operator ==(other) =>
      other is Ability &&
      name == other.name &&
      level == other.level &&
      caster == other.caster;

  @override
  int get hashCode => hash3(name.hashCode, level.hashCode, caster);
}

class Perestroika extends Ability {
  Perestroika({
    required super.caster,
    required super.level,
    this.numTargets = const [2, 3, 4, 5, 6],
  });

  List<int> numTargets;

  @override
  String name = "Perestroika";

  @override
  String description = "Fires at multiple enemies";

  @override
  String get subDescription => "${numTargets.join("/")} targets";

  @override
  IconData icon = Icons.call_split;

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
  CityType gemType = CityType.EEUROPE;
}

class Burn extends Ability {
  Burn({required super.caster, required super.level});

  @override
  bool get worksOnEnemies => true;

  @override
  bf.Buff? get buff => bf.Burn(caster: caster, level: level);

  @override
  String name = "Burn";

  @override
  String description = "Damages enemies over time.";

  @override
  String get subDescription =>
      "${bf.Burn.damagePerLevel.join("/")} damage per second.";

  @override
  IconData icon = Icons.whatshot;

  @override
  CityType gemType = CityType.SAMERICA;
}

class Bloom extends Ability {
  Bloom({required super.caster, required super.level});

  static const spreadCountPerLevel = [1, 1, 2, 2, 3, 3];

  @override
  String name = "Bloom";

  @override
  String description = "Attacks spread burn to nearby enemies.";

  @override
  String get subDescription =>
      "${spreadCountPerLevel.join("/")} extra targets.";

  @override
  IconData icon = FontAwesomeIcons.seedling.data;

  @override
  CityType gemType = CityType.SAMERICA;

  @override
  GameComponent? onEnemyAttack(GemComponent gem, EnemyComponent primaryTarget,
      Set<GameComponent> targets) {
    int count = spreadCountPerLevel.getByLevel(level);
    int i = 0;
    for (var target in targets) {
      if (target == primaryTarget) continue;
      if (i >= count) break;
      if (target is EnemyComponent) {
        var burn = bf.Burn(caster: caster, level: level);
        if (target.buffs.contains(burn)) {
          target.buffs.firstWhere((b) => b == burn).resetDuration();
        } else {
          target.buffs.add(burn);
        }
        i++;
      }
    }
    return null;
  }
}

class ColombianRoast extends Ability {
  ColombianRoast({required super.caster, required super.level});

  @override
  bool get worksOnEnemies => true;

  @override
  bf.Buff? get buff => bf.ColombianRoast(caster: caster, level: level);

  @override
  String name = "Colombian Roast";

  @override
  String description = "Stacking burn that increases damage with each hit.";

  @override
  String get subDescription =>
      "${bf.ColombianRoast.damagePerStack.join("/")} damage per stack.";

  @override
  IconData icon = FontAwesomeIcons.fireFlameCurved.data;

  @override
  CityType gemType = CityType.SAMERICA;
}

class Inti extends Ability {
  Inti({required super.caster, required super.level});

  @override
  bool get worksOnEnemies => true;

  @override
  bf.Buff? get buff => bf.Inti(caster: caster, level: level);

  @override
  String name = "Inti";

  @override
  String description = "Enemies take increased damage from all sources.";

  @override
  String get subDescription =>
      "${bf.Inti.multiplierPerLevel.map((e) => "${(e * 100).toStringAsFixed(0)}%").join("/")} increased damage.";

  @override
  IconData icon = FontAwesomeIcons.sun.data;

  @override
  CityType gemType = CityType.SAMERICA;
}

class Carnival extends Ability {
  Carnival({required super.caster, required super.level});

  static var chancePerLevel = [0.15, 0.20, 0.25, 0.30, 0.35, 0.40];

  @override
  double? get baseChance => chancePerLevel.getByLevel(level);

  @override
  String name = "Carnival";

  @override
  String description = "Chance to fire at all enemies in range.";

  @override
  String get subDescription =>
      "${chancePerLevel.map((e) => "${(e * 100).toStringAsFixed(0)}%").join("/")} chance.";

  @override
  bool get canAttack => false;

  @override
  IconData icon = FontAwesomeIcons.masksTheater.data;

  @override
  CityType gemType = CityType.SAMERICA;

  @override
  GameComponent? onEnemyAttack(GemComponent gem, EnemyComponent primaryTarget,
      Set<GameComponent> targets) {
    if (Random().nextDouble() < currentChance!) {
      for (var target in targets) {
        gem.fire(target as EnemyComponent);
      }
    } else {
      gem.fire(primaryTarget);
    }
    return null;
  }
}

class Asado extends Ability {
  Asado({required super.caster, required super.level});

  @override
  bool get worksOnEnemies => true;

  @override
  bf.Buff? get buff => bf.Asado(caster: caster, level: level);

  @override
  String name = "Asado";

  @override
  String description = "Escalating burn that grows stronger over time.";

  @override
  String get subDescription =>
      "${bf.Asado.baseDamagePerLevel.join("/")} base damage.\n"
      "${bf.Asado.escalationPerLevel.join("/")} extra per second.";

  @override
  IconData icon = FontAwesomeIcons.fireFlameSimple.data;

  @override
  CityType gemType = CityType.SAMERICA;
}

class Furnace extends Ability {
  Furnace({required super.caster, required super.level});

  @override
  bool get worksOnEnemies => true;

  @override
  bf.Buff? get buff => bf.Furnace(caster: caster, level: level);

  @override
  String name = "Furnace";

  @override
  String description = "Strips armor from burning enemies.";

  @override
  String get subDescription =>
      "Duration: ${bf.Furnace.durationPerLevel.join("/")}s.";

  @override
  IconData icon = FontAwesomeIcons.industry.data;

  @override
  CityType gemType = CityType.SAMERICA;
}

class Allure extends Ability {
  Allure({required super.caster, required super.level});

  @override
  bool get worksOnEnemies => true;

  @override
  bf.Buff? get buff => bf.Lust(caster: caster, level: level);

  @override
  String name = "Allure";

  @override
  String description = "Reduces the armor of enemies.";

  @override
  String get subDescription =>
      "${bf.Lust.reductionPerLevel.join("/")} resistance reduction.";

  @override
  IconData icon = FontAwesomeIcons.peace.data;

  @override
  CityType gemType = CityType.ASEAN;
}

class GreenIsGold extends Ability {
  GreenIsGold({required super.caster, required super.level});

  @override
  bool get worksOnEnemies => true;

  @override
  bf.Buff? get buff => bf.BountyMultiple(
        caster: caster,
        level: level,
        overrideBaseDuration: 1,
      );

  @override
  String name = "Green Is Gold";

  @override
  String description = "Increases the bounty on enemies killed.";

  @override
  String get subDescription =>
      "${bf.BountyMultiple.defaultMultipliers.join("/")} bounty increase.";

  @override
  IconData icon = FontAwesomeIcons.moneyBill.data;

  @override
  CityType gemType = CityType.ASEAN;
}

class Poison extends Ability {
  Poison({required super.caster, required super.level});

  @override
  bool get worksOnEnemies => true;

  @override
  bf.Buff? get buff => bf.Poison(caster: caster, level: level);

  @override
  String name = "Spice Route";

  @override
  String description = "Spices slow and damage enemies over time.";

  @override
  String get subDescription =>
      "${bf.Poison.damagePerLevel.join("/")} damage per second.\n"
      "${bf.Poison.slowPerLevel.join("/")} slow.";

  @override
  IconData icon = Icons.sick_outlined;

  @override
  CityType gemType = CityType.SASIA;
}

class Serendipity extends Ability {
  Serendipity({required super.caster, required super.level});

  static var chancePerLevel = [0.99, 0.20, 0.25, 0.30, 0.35, 0.40];

  @override
  double? get baseChance => chancePerLevel.getByLevel(level);

  @override
  bool get worksOnEnemies => true;

  @override
  bf.Buff? get buff => Random().nextDouble() < currentChance!
      ? bf.Hex(caster: caster, level: level)
      : null;

  @override
  String name = "Serendipity";

  @override
  String description = "Chance to hex enemies into critters.";

  @override
  String get subDescription =>
      "${chancePerLevel.map((e) => "${(e * 100).toStringAsFixed(0)}%").join("/")} chance to hex for\n"
      "${bf.Hex.durationPerLevel.join("/")} seconds.";

  @override
  IconData icon = FontAwesomeIcons.frog.data;

  @override
  CityType gemType = CityType.SASIA;
}

class Petronas extends Ability {
  Petronas({required super.caster, required super.level});

  @override
  bool get worksOnEnemies => true;

  @override
  bf.Buff? get buff => bf.Petronas(caster: caster, level: level);

  @override
  String name = "Petronas";

  @override
  String description = "Slows enemies.";

  @override
  String get subDescription => "${bf.Petronas.slowPerLevel.join("/")} slow.";

  @override
  IconData icon = Icons.oil_barrel;

  @override
  CityType gemType = CityType.ASEAN;
}

class Disruption extends Ability {
  Disruption({required super.caster, required super.level});

  @override
  bool get worksOnEnemies => true;

  @override
  bf.Buff? get buff => bf.Disruption(caster: caster, level: level);

  @override
  String name = "Disruption";

  @override
  String description = "Reduces an enemy's armor.";

  @override
  String get subDescription =>
      "${bf.Disruption.reductionPerLevel.join("/")} resistance reduction.";

  @override
  IconData icon = Icons.broken_image;

  @override
  CityType gemType = CityType.EASIA;
}

class Balance extends Ability {
  Balance({required super.caster, required super.level});

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
  String name = "Balance";

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

class RedCapitalism extends Ability {
  RedCapitalism({required super.caster, required super.level});

  static var chancePerLevel = [0.3, 0.35, 0.4, 0.45, 0.5];

  @override
  double? get baseChance => chancePerLevel.getByLevel(level);

  @override
  bool get worksOnEnemies => true;

  bool _nextProc = false;
  bool _firstCall = true;

  bool _nextBool() {
    if (_firstCall) {
      var nextBool = Random().nextDouble() < currentChance!;
      _nextProc = nextBool;
      _firstCall = false;
      return nextBool;
    } else {
      _firstCall = true;
      return _nextProc;
    }
  }

  @override
  bf.Buff? get buff =>
      _nextBool() ? bf.Stun(caster: caster, level: level) : null;

  @override
  String name = "Red Capitalism";

  @override
  String description = "Gives a chance to increase damage and stun an enemy.";

  @override
  String get subDescription => "${chancePerLevel.join("/")} chance to deal\n"
      "${bf.CriticalStrike.damageMultiples.join("/")}x damage and\n"
      "stun for ${bf.Stun.durationPerLevel.join("/")} seconds.";

  @override
  IconData icon = FontAwesomeIcons.dice.data;

  @override
  CityType gemType = CityType.EASIA;

  @override
  onEnemyAttack(GemComponent gem, EnemyComponent primaryTarget,
      Set<GameComponent> targets) {
    if (_nextBool()) {
      var cs = bf.CriticalStrike(caster: gem, level: level);
      if (gem.buffs.contains(cs)) {
        gem.buffs.forEach((b) {
          if (b == cs) {
            b.duration = cs.duration;
          }
        });
      } else {
        gem.buffs.add(cs);
      }
    }
  }
}

class ManufacturedTechnology extends Ability {
  ManufacturedTechnology({required super.caster, required super.level});

  @override
  String name = "Manufactured Technology";

  @override
  String description =
      "Increases attack range and causes all chance abilities to cast 100% of the time."
      "\nReduces attack damage, and all debuff durations by 95%.";

  @override
  String get subDescription =>
      "${bf.ManufacturedTechnology.fraction.join("/")}x attack speed"
      "\n${bf.ManufacturedTechnology.fraction.map((e) => "1/$e").join("/")}x damage";

  @override
  bool get worksOnSelf => true;

  @override
  bf.Buff? get buff => bf.ManufacturedTechnology(caster: caster, level: level);

  @override
  IconData icon = Icons.copy_all;

  @override
  CityType gemType = CityType.EASIA;
}

class Tether extends Ability {
  static const _max = 100;
  static const increasePerLevel = [0.2, 0.3, 0.4, 0.5, 0.6];

  Tether({required super.caster, required super.level});

  int count = 0;

  @override
  String name = "Tether";

  @override
  String description = "Forms a tether on attack.";

  @override
  String get subDescription => "${increasePerLevel.join("/")} per attack.";

  @override
  onEnemyAttack(GemComponent gem, EnemyComponent primaryTarget, Set targets) {
    if (caster.lastEnemy == primaryTarget) {
      if (count < _max) count++;
      var buff = bf.AttackSpeedMultiple(
          caster: caster,
          level: level,
          overrideDurationType: bf.DurationType.ATTACK,
          overrideMultiplier: 1 + count * increasePerLevel.getByLevel(level));
      gem.buffs.add(buff);
    } else {
      count = 0;
    }
    return null;
  }

  @override
  CityType gemType = CityType.WEUROPE;

  @override
  IconData icon = Icons.link;
}

class Caffeination extends Ability {
  Caffeination({required super.caster, required super.level});

  @override
  String name = "Caffeination";

  @override
  String description =
      "Increases upfront attack speed for a given enemy, while decreasing overall attack speed.";

  @override
  String get subDescription =>
      "First $numberOfAttacks attacks at ${increasePerLevel.join("/")}x speed.\n"
      "Subsequent attacks at ${increasePerLevel.map((e) => "1/$e").join("/")}x speed.";

  static List<double> increasePerLevel = [2.3, 2.6, 2.9, 3.2, 3.5, 3.8];

  @override
  double? get increase => increasePerLevel.getByLevel(level);

  int count = 0;
  late int numberOfAttacks = level + 1;

  @override
  onEnemyAttack(GemComponent gem, EnemyComponent enemy, Set targets) {
    if (gem.lastEnemy != enemy) {
      count = 0;
    }
    if (count < numberOfAttacks - 1) {
      count++;
      var buff = bf.AttackSpeedMultiple(
        caster: caster,
        level: level,
        overrideDurationType: bf.DurationType.ATTACK,
        overrideMultiplier: increasePerLevel.getByLevel(level),
      );
      gem.buffs.add(buff);
    } else {
      var buff = bf.AttackSpeedMultiple(
        caster: caster,
        level: level,
        overrideDurationType: bf.DurationType.ATTACK,
        overrideMultiplier: 1 / increasePerLevel[count - 1],
      );
      gem.buffs.add(buff);
    }
  }

  @override
  CityType gemType = CityType.NAMERICA;

  @override
  IconData icon = Icons.coffee;
}

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

class KPOP extends Ability {
  KPOP({required super.caster, required super.level});

  @override
  String name = "K-Pop";

  @override
  String description =
      "Attacks reduce enemy armor, but also increase enemy movement speed.";

  @override
  String get subDescription =>
      "${bf.KPOP.reductionPerLevel.join("/")} minus armor."
      "\n${bf.KPOP.slowPerLevel.join("/")} movement speed.";

  @override
  bf.Buff? get buff => bf.KPOP(
        caster: caster,
        level: level,
      );

  @override
  bool get worksOnEnemies => true;

  @override
  CityType gemType = CityType.EASIA;

  @override
  IconData icon = FontAwesomeIcons.music.data;
}

class EchoChamber extends Ability {
  final int _max = 10;

  EchoChamber({required super.caster, required super.level});

  @override
  String name = "Echo Chamber";

  @override
  String description = "Each subsequent attack doubles the prior damage.";

  @override
  String get subDescription => "";

  double get increase => 2;

  @override
  onEnemyAttack(GemComponent gem, EnemyComponent enemy, Set targets) {
    var nextDamage = getDamageMultiple(enemy, gem.currentDamage);

    if (count >= 1) {
      var cs = bf.CriticalStrike(
          caster: gem, overrideDamageMultiplier: nextDamage, level: level);
      if (gem.buffs.contains(cs)) {
        gem.buffs.forEach((b) {
          if (b == cs) {
            b.duration = cs.duration;
            (b as bf.CriticalStrike).overrideDamageMultiplier =
                cs.overrideDamageMultiplier;
          }
        });
      } else {
        gem.buffs.add(cs);
      }
    }
  }

  int count = 0;

  double getDamageMultiple(EnemyComponent? enemy, double baseDamage) {
    if (caster.lastEnemy == enemy) {
      if (count < _max) count++;
      return baseDamage * pow(2, count);
    } else {
      count = 0;
      return baseDamage;
    }
  }

  @override
  CityType gemType = CityType.ASEAN;

  @override
  IconData icon = Icons.speaker;
}

// TODO(unused, should remove?)
// class CriticalStrike extends Ability {
//   CriticalStrike({required super.caster, required super.level});
//
//   static var chancePerLevel = [0.3, 0.35, 0.4, 0.45, 0.5];
//
//   @override
//   double? get baseChance => chancePerLevel.getByLevel(level);
//
//   @override
//   String name = "Critical Strike";
//
//   @override
//   String description = "Gives a chance to increase damage.";
//
//   @override
//   String get subDescription => "${chancePerLevel.join("/")} chance to deal\n"
//       "${bf.CriticalStrike.damageMultiples.join("/")}x damage.";
//
//   @override
//   IconData icon = Icons.strikethrough_s;
//
//   @override
//   CityType gemType = CityType.NAMERICA;
//
//   @override
//   onEnemyAttack(GemComponent gem, EnemyComponent primaryTarget,
//       Set<GameComponent> targets) {
//     if (Random().nextDouble() < currentChance!) {
//       var cs = bf.CriticalStrike(caster: gem, level: level);
//       if (gem.buffs.contains(cs)) {
//         gem.buffs.forEach((b) {
//           if (b == cs) {
//             b.duration = cs.duration;
//           }
//         });
//       } else {
//         gem.buffs.add(cs);
//       }
//     }
//   }
// }

class Capitalism extends Ability {
  Capitalism({required super.caster, required super.level});

  static var chancePerLevel = [0.3, 0.35, 0.4, 0.45, 0.5, 0.55];

  @override
  double? get baseChance => chancePerLevel.getByLevel(level);

  static var multiplierPerLevel = [2.0, 2.25, 2.5, 2.75, 3.0, 3.25];

  @override
  double? get multiplier => multiplierPerLevel.getByLevel(level);

  @override
  String name = "Capitalism";

  @override
  String description = "Gives a chance to increase or decrease damage.";

  @override
  String get subDescription =>
      "${chancePerLevel.map((e) => (e * 100).toStringAsFixed(0) + "%").join("/")} chance to "
      "increase/decrease damage by ${multiplierPerLevel.map((e) => (e * 100).toStringAsFixed(0) + "%").join("/")}";

  Random r = Random();

  double nextMuliplier() {
    return r.nextDouble() < currentChance!
        ? 1
        : r.nextBool()
            ? multiplier!
            : 1 / multiplier!;
  }

  @override
  IconData icon = FontAwesomeIcons.dice.data;

  @override
  CityType gemType = CityType.NAMERICA;

  @override
  onEnemyAttack(GemComponent gem, EnemyComponent primaryTarget,
      Set<GameComponent> targets) {
    var multiplier = nextMuliplier();
    if (multiplier != 1) {
      var cs = bf.CriticalStrike(
          caster: gem, level: level, overrideDamageMultiplier: multiplier);
      if (gem.buffs.contains(cs)) {
        gem.buffs.forEach((b) {
          if (b == cs) {
            b.duration = cs.duration;
          }
        });
      } else {
        gem.buffs.add(cs);
      }
    }
  }
}

class VentureCapitalism extends Ability {
  VentureCapitalism({required super.caster, required super.level});

  static var chancePerLevel = [0.3, 0.35, 0.4, 0.45, 0.5];

  @override
  double? get baseChance => chancePerLevel.getByLevel(level);

  static var multiplierPerLevel = [5.5, 6.0, 6.5, 7.0, 7.5, 8.0];

  @override
  double? get multiplier => multiplierPerLevel.getByLevel(level);

  @override
  String name = "Venture Capitalism";

  @override
  String description = "Attacks either do 0 damage or a huge multiple.";

  @override
  String get subDescription =>
      "${chancePerLevel.map((e) => (e * 100).toStringAsFixed(0) + "%").join("/")} chance to "
      "increase damage by ${multiplierPerLevel.map((e) => (e * 100).toStringAsFixed(0) + "%").join("/")}";

  Random r = Random();

  double nextMuliplier() {
    return r.nextDouble() < currentChance! ? multiplier! : 0;
  }

  @override
  IconData icon = FontAwesomeIcons.diceD20.data;

  @override
  CityType gemType = CityType.NAMERICA;

  @override
  onEnemyAttack(GemComponent gem, EnemyComponent primaryTarget,
      Set<GameComponent> targets) {
    var multiplier = nextMuliplier();
    if (multiplier != 1) {
      var cs = bf.CriticalStrike(
          caster: gem, level: level, overrideDamageMultiplier: multiplier);
      if (gem.buffs.contains(cs)) {
        gem.buffs.forEach((b) {
          if (b == cs) {
            b.duration = cs.duration;
          }
        });
      } else {
        gem.buffs.add(cs);
      }
    }
  }
}

class Telescope extends Ability {
  Telescope({required super.caster, required super.level});

  @override
  String name = "Telescope";

  @override
  bf.Buff? get buff => bf.Telescope(caster: caster, level: level);

  @override
  String description = "Increases attack range of nearby gems.";

  @override
  String get subDescription => "${bf.Telescope.rangePerLevel.join("/")} range.";

  @override
  bool get alliesAura => true;

  @override
  IconData icon = Icons.radar;

  @override
  CityType gemType = CityType.EASIA;
}

class ManagedRisk extends Ability {
  ManagedRisk({required super.caster, required super.level});

  @override
  String name = "Managed Risk";

  @override
  bf.Buff? get buff => bf.DamageMultiple(caster: caster, level: level);

  @override
  String description = "Increases attack damage of nearby gems.";

  @override
  String get subDescription =>
      "${bf.DamageMultiple.defaultMultipliers.map((e) => "${(e * 100).toStringAsFixed(0)}%  ").join("/")} damage.";

  @override
  bool get alliesAura => true;

  @override
  IconData icon = Icons.stacked_bar_chart;

  @override
  CityType gemType = CityType.NAMERICA;
}

// MENA spine: Religion is an ALLY damage-buff aura (MENA never attacks).
class Religion extends Ability {
  Religion({required super.caster, required super.level});

  static const damageBuffPerLevel = [1.15, 1.2, 1.25, 1.3, 1.35, 1.4];

  @override
  String name = "Religion";

  @override
  bf.Buff? get buff => bf.DamageMultiple(
        caster: caster,
        level: level,
        multipliersPerLevel: damageBuffPerLevel,
      )
        ..name = name
        ..icon = icon
        ..gemType = gemType;

  @override
  String description = "Increases the attack damage of nearby allied cities.";

  @override
  String get subDescription =>
      "${damageBuffPerLevel.map((e) => "${(e * 100).toStringAsFixed(0)}%").join("/")} ally damage.";

  @override
  bool get canAttack => false;

  @override
  bool get alliesAura => true;

  @override
  CityType gemType = CityType.MENA;

  @override
  IconData icon = FontAwesomeIcons.placeOfWorship.data;
}

// Beirut — Cedars of Lebanon: amplifies the buffs of nearby allied cities.
class CedarsOfLebanon extends Ability {
  CedarsOfLebanon({required super.caster, required super.level});

  @override
  String name = "Cedars of Lebanon";

  @override
  bf.Buff? get buff => bf.BuffMultiple(caster: caster, level: level)
    ..name = name
    ..icon = icon
    ..gemType = gemType;

  @override
  String description = "Amplifies the buffs of nearby allied cities.";

  @override
  String get subDescription =>
      "${bf.BuffMultiple.defaultMultipliers.map((e) => "${(e * 100).toStringAsFixed(0)}%").join("/")} buff strength.";

  @override
  bool get canAttack => false;

  @override
  bool get alliesAura => true;

  @override
  CityType gemType = CityType.MENA;

  @override
  IconData icon = FontAwesomeIcons.tree.data;
}

class CityOfJasmine extends Ability {
  CityOfJasmine({required super.caster, required super.level});

  @override
  String name = "City of Jasmine";

  @override
  bf.Buff? get buff => bf.ReceiveDamageMultiple(
        caster: caster,
        level: level,
        overrideMultiplier: caster.bounty / 100,
        overrideBaseDuration: 0.4,
      );

  @override
  String description = "Multiplies Damage Received by a % of capital.";

  @override
  String get subDescription => "1% of capital";

  @override
  bool get canAttack => false;

  @override
  bool get worksOnSelf => false;

  @override
  bool get enemiesAura => true;

  @override
  CityType gemType = CityType.MENA;

  @override
  IconData icon = FontAwesomeIcons.fan.data;
}

// Cairo — Sphinx: chance to afflict nearby enemies with a random curse.
class Sphinx extends Ability {
  Sphinx({required super.caster, required super.level});

  static var chancePerLevel = [0.15, 0.20, 0.25, 0.30, 0.35, 0.40];

  @override
  double? get baseChance => chancePerLevel.getByLevel(level);

  final Random _r = Random();

  @override
  String name = "Sphinx";

  @override
  String description = "Chance to afflict nearby enemies with a random curse.";

  @override
  String get subDescription =>
      "${chancePerLevel.map((e) => "${(e * 100).toStringAsFixed(0)}%").join("/")} chance per enemy.";

  @override
  bool get canAttack => false;

  @override
  CityType gemType = CityType.MENA;

  @override
  IconData icon = FontAwesomeIcons.cat.data;

  bf.Buff _randomCurse() {
    switch (_r.nextInt(4)) {
      case 0:
        return bf.SpeedModify(
            caster: caster,
            level: level,
            modifier: 0.3,
            overrideBaseDuration: 2)
          ..name = "Curse: Slow"
          ..icon = icon
          ..gemType = gemType;
      case 1:
        return bf.ArmorModify(
            caster: caster, level: level, modifier: 6, overrideBaseDuration: 2)
          ..name = "Curse: Exposed"
          ..icon = icon
          ..gemType = gemType;
      case 2:
        return bf.ReceiveDamageMultiple(
            caster: caster,
            level: level,
            overrideMultiplier: 0.3,
            overrideBaseDuration: 2)
          ..name = "Curse: Vulnerable"
          ..icon = icon
          ..gemType = gemType;
      default:
        return bf.Stun(caster: caster, level: level)..gemType = gemType;
    }
  }

  @override
  GameComponent? onEnemyAttack(GemComponent gem, EnemyComponent primaryTarget,
      Set<GameComponent> targets) {
    for (var t in targets) {
      if (t is EnemyComponent && _r.nextDouble() < (currentChance ?? 0)) {
        t.buffs.add(_randomCurse());
      }
    }
    return null;
  }
}

// Riyadh — Black Gold: coats nearby enemies in Oiled (slow + amplified damage).
class BlackGold extends Ability {
  BlackGold({required super.caster, required super.level});

  @override
  String name = "Black Gold";

  @override
  bf.Buff? get buff => bf.Oiled(caster: caster, level: level)..gemType = gemType;

  @override
  String description =
      "Coats nearby enemies in oil — slowing them and amplifying damage taken.";

  @override
  String get subDescription =>
      "${bf.Oiled.slowPerLevel.map((e) => "${(e * 100).toStringAsFixed(0)}%").join("/")} slow.";

  @override
  bool get canAttack => false;

  @override
  bool get enemiesAura => true;

  @override
  CityType gemType = CityType.MENA;

  @override
  IconData icon = Icons.oil_barrel;
}

class StartupNation extends Ability {
  StartupNation({required super.caster, required super.level});

  @override
  String name = "Startup Nation";

  @override
  bf.Buff? get buff => bf.StartupNation(caster: caster, level: level);

  @override
  String description = "Amplifies the bounty-to-damage scalar of nearby gems.";

  @override
  String get subDescription =>
      "${bf.StartupNation.scalarPerLevel.join("/")}x bounty damage scalar.";

  @override
  bool get canAttack => false;

  @override
  bool get alliesAura => true;

  @override
  CityType gemType = CityType.MENA;

  @override
  IconData icon = FontAwesomeIcons.rocket.data;
}

class GoldenSouk extends Ability {
  GoldenSouk({required super.caster, required super.level});

  @override
  String name = "Golden Souk";

  @override
  bf.Buff? get buff => bf.BountyMultiple(caster: caster, level: level);

  @override
  String description = "Increases the bounty on enemies in range.";

  @override
  String get subDescription =>
      "${bf.BountyMultiple.defaultMultipliers.join("/")}x bounty.";

  @override
  bool get canAttack => false;

  @override
  bool get enemiesAura => true;

  @override
  CityType gemType = CityType.MENA;

  @override
  IconData icon = FontAwesomeIcons.coins.data;
}

class FullMoon extends Ability {
  FullMoon({required super.caster, required super.level});

  @override
  String name = "Full Moon";

  @override
  bool get worksOnSelf => true;

  @override
  String description =
      "Greatly increases attack range, but attacks a random target.";

  @override
  bf.Buff? get buff => bf.Telescope(caster: caster, level: level);

  @override
  String get subDescription => "${bf.Telescope.rangePerLevel.join("/")} range.";

  @override
  GameComponent? onEnemyAttack(GemComponent gem, EnemyComponent primaryTarget,
      Set<GameComponent> targets) {
    int i = Random().nextInt(targets.length);

    return targets.elementAt(i);
  }

  @override
  CityType gemType = CityType.NAMERICA;

  @override
  IconData icon = FontAwesomeIcons.solidHeart.data;
}

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

class GreatWall extends Ability {
  GreatWall({required super.caster, required super.level});

  @override
  String name = "Great Wall";

  @override
  bool get worksOnSelf => true;

  @override
  String description = "Increases attack speed but decreases range.";

  @override
  bf.Buff? get buff => bf.GreatWall(caster: caster, level: level);

  @override
  String get subDescription =>
      "${bf.GreatWall.fraction.join("/")}x attack speed."
      "\n${bf.GreatWall.fraction.map((e) => (1 / e).toStringAsFixed(1)).join("/")}x range.";

  @override
  CityType gemType = CityType.EASIA;

  @override
  IconData icon = FontAwesomeIcons.gopuram.data;
}

class BrotherlyLove extends Ability {
  BrotherlyLove({
    required super.caster,
    required super.level,
    required this.range,
  });

  double range;

  @override
  String name = "Brotherly Love";

  @override
  String description = "Attacks bounce to nearby enemies.";

  @override
  String get subDescription => level == 1
      ? "Bounces to ${bf.ChainAttack.bouncesPerLevel.getByLevel(level)} enemy."
      : "Bounces to ${bf.ChainAttack.bouncesPerLevel.getByLevel(level)} enemies.";

  @override
  bf.Buff? get buff => bf.ChainAttack(
        caster: caster,
        level: level,
        range: range,
      );

  @override
  bool get worksOnEnemies => true;

  @override
  CityType gemType = CityType.NAMERICA;

  @override
  IconData icon = FontAwesomeIcons.handshakeAngle.data;
}

// Los Angeles — Hollywood: a low chance to turn an enemy into a Star, which is
// invulnerable & debuff-immune while it shines, then dies (a timed guaranteed
// kill — but it keeps marching untouchable, so it can leak if starred late).
class Hollywood extends Ability {
  Hollywood({required super.caster, required super.level});

  static var chancePerLevel = [0.03, 0.04, 0.05, 0.06, 0.07, 0.08];

  @override
  double? get baseChance => chancePerLevel.getByLevel(level);

  @override
  bool get worksOnEnemies => true;

  @override
  bf.Buff? get buff => Random().nextDouble() < (currentChance ?? 0)
      ? bf.Star(caster: caster, level: level)
      : null;

  @override
  String name = "Hollywood";

  @override
  String description =
      "Low chance to turn an enemy into a Star — invulnerable, then it dies.";

  @override
  String get subDescription =>
      "${chancePerLevel.map((e) => "${(e * 100).toStringAsFixed(0)}%").join("/")} chance to make a Star for "
      "${bf.Star.durationPerLevel.join("/")}s.";

  @override
  IconData icon = FontAwesomeIcons.film.data;

  @override
  CityType gemType = CityType.NAMERICA;
}

// Toronto — Immigration: elevated base damage that decreases for each nearby
// allied (non-Rock) tower. Strongest in isolation. Applies per attack, so it
// works even when the tower is alone (unlike a pure allies-aura).
class Immigration extends Ability {
  Immigration({required super.caster, required super.level});

  static const baseMult = [2.0, 2.3, 2.6, 2.9, 3.2, 3.5];
  static const decrementPerTower = 0.2;
  static const minMult = 0.5;

  int _nearbyCount = 0;

  @override
  void onAuraScan(Set<GemComponent> gems) {
    _nearbyCount = gems
        .where((g) => g != caster && g.gemType != CityType.ROCK)
        .length;
  }

  double get _mult {
    final m = baseMult.getByLevel(level) - _nearbyCount * decrementPerTower;
    return m < minMult ? minMult : m;
  }

  @override
  GameComponent? onEnemyAttack(GemComponent gem, EnemyComponent primaryTarget,
      Set<GameComponent> targets) {
    final cs = bf.CriticalStrike(
        caster: gem, level: level, overrideDamageMultiplier: _mult)
      ..name = name
      ..icon = icon
      ..gemType = gemType;
    if (gem.buffs.contains(cs)) {
      for (var b in gem.buffs) {
        if (b == cs) {
          b.duration = cs.duration;
          (b as bf.CriticalStrike).overrideDamageMultiplier =
              cs.overrideDamageMultiplier;
        }
      }
    } else {
      gem.buffs.add(cs);
    }
    return null;
  }

  @override
  String name = "Immigration";

  @override
  String description =
      "Elevated damage that decreases for each nearby allied tower — strongest alone.";

  @override
  String get subDescription =>
      "${baseMult.map((e) => "${(e * 100).toStringAsFixed(0)}%").join("/")} damage, "
      "-${(decrementPerTower * 100).toStringAsFixed(0)}% per nearby tower.";

  @override
  IconData icon = FontAwesomeIcons.peopleArrows.data;

  @override
  CityType gemType = CityType.NAMERICA;
}

class WallStreet extends Ability {
  WallStreet({required super.caster, required super.level}) {
    timer = Timer.periodic(Duration(seconds: 3), (timer) {
      nextDamage();
      //TODO(alex) do we use _buff object?
      // _buff.multiplier = _multiple;
    });
  }

  late final Timer timer;

  double _multiple = 1.0;

  @override
  void onGemDestroyed(GemComponent gem) {
    timer.cancel();
    super.onGemDestroyed(gem);
  }

  void nextDamage() {
    _multiple = (damagePerLevel.getByLevel(level) -
                1 / damagePerLevel.getByLevel(level)) *
            Random().nextDouble() +
        1 / damagePerLevel.getByLevel(level);
  }

  @override
  String name = "Wall Street";

  //TODO(alex) do we need _buff object?
  // late final _buff = bf.DamageMultiple(caster: caster, level: level);

  @override
  bf.Buff? get buff => bf.DamageMultiple(caster: caster, level: level);

  List<double> get damagePerLevel => [1.9, 2.1, 2.3, 2.5, 2.7, 2.9];

  @override
  String description =
      "Randomly increases or decreases attack damage of nearby gems.";

  @override
  String get subDescription =>
      "Multiplies damage of nearby cities by a number between 1/${damagePerLevel.getByLevel(level)} and ${damagePerLevel.getByLevel(level)}.";

  @override
  bool get alliesAura => true;

  @override
  IconData icon = Icons.stacked_bar_chart;

  @override
  CityType gemType = CityType.NAMERICA;

  @override
  void onAuraScan(Set<GemComponent> gems) {
    if (alliesAura) {
      gems.forEach((gem) {
        if (gem.buffs.contains(buff!)) {
          var bff = gem.buffs.firstWhere((element) => element == buff);
          bff.duration = buff!.duration;
          if (bff is bf.DamageMultiple) {
            bff.overrideMultiplier = _multiple;
          }
        } else {
          gem.buffs.add(buff!);
        }
      });
    }
  }
}

// The ability fires multiple attacks in immediate secession, followed by a
// regular cool-down, then fires attacks in immediate secession, and so on.)
class SequentialAttack extends Ability {
  SequentialAttack({required super.caster, required super.level});

  @override
  IconData icon = bf.SequentialAttack.iconDefault;

  @override
  CityType gemType = CityType.ASEAN;

  @override
  String name = "Sequential Attack";

  @override
  late String description =
      "Multiple attacks in immediate secession, followed by the regular cool-down.";

  @override
  String get subDescription => "";

  @override
  bool get worksOnSelf => true;

  @override
  void onAuraScan(Set<GemComponent> gems) {
    if (caster.gameRef.gameStats.isWaveActive) {
      if (buff == null && mayApplyBuff()) {
        buff = createBuff();
      }
    } else {
      (buff as bf.SequentialAttack?)?.reset();
    }
    super.onAuraScan(gems);
  }

  bool mayApplyBuff() => true;

  bf.SequentialAttack createBuff() =>
      bf.SequentialAttack(caster: caster, level: level);
}

// ============================================================================
// South America — burn / DoT region
// ============================================================================

// Medellín — Cartel: greatly increases the capital gained from struck enemies.
class Cartel extends Ability {
  Cartel({required super.caster, required super.level});

  static const multipliers = [1.0, 1.5, 2.0, 2.5, 3.0, 3.5];

  @override
  bool get worksOnEnemies => true;

  @override
  bf.Buff? get buff => bf.BountyMultiple(
        caster: caster,
        level: level,
        multipliersPerLevel: multipliers,
        overrideBaseDuration: 4,
      );

  @override
  String name = "Cartel";

  @override
  String description = "Enemies are worth far more capital when killed.";

  @override
  String get subDescription =>
      "${multipliers.map((e) => "${(e * 100).toStringAsFixed(0)}%").join("/")} capital.";

  @override
  IconData icon = FontAwesomeIcons.moneyBillTrendUp.data;

  @override
  CityType gemType = CityType.SAMERICA;
}

// Caracas — Crude: coats enemies in oil (slow + amplified damage taken).
class Crude extends Ability {
  Crude({required super.caster, required super.level});

  @override
  bool get worksOnEnemies => true;

  @override
  bf.Buff? get buff => bf.Oiled(caster: caster, level: level);

  @override
  String name = "Crude";

  @override
  String description =
      "Coats enemies in oil — slowing them and amplifying the damage they take.";

  @override
  String get subDescription =>
      "${bf.Oiled.slowPerLevel.map((e) => "${(e * 100).toStringAsFixed(0)}%").join("/")} slow.\n"
      "${bf.Oiled.dmgAmpPerLevel.map((e) => "${(e * 100).toStringAsFixed(0)}%").join("/")} amplified damage.";

  @override
  IconData icon = Icons.oil_barrel;

  @override
  CityType gemType = CityType.SAMERICA;
}

// Rio — Redeemer: a chance to "redeem" an enemy so that, if it leaks, it costs
// no capital (implemented as a bounty multiplier of -1 → enemy capital becomes 0).
class Redeemer extends Ability {
  Redeemer({required super.caster, required super.level});

  static var chancePerLevel = [0.15, 0.20, 0.25, 0.30, 0.35, 0.40];

  @override
  double? get baseChance => chancePerLevel.getByLevel(level);

  @override
  bool get worksOnEnemies => true;

  @override
  bf.Buff? get buff => Random().nextDouble() < (currentChance ?? 0)
      ? bf.BountyMultiple(
          caster: caster,
          level: level,
          overrideMultiplier: -1.0,
          overrideBaseDuration: null, // permanent redemption
        )
      : null;

  @override
  String name = "Redeemer";

  @override
  String description =
      "Chance to redeem an enemy so that, should it leak, it costs no capital.";

  @override
  String get subDescription =>
      "${chancePerLevel.map((e) => "${(e * 100).toStringAsFixed(0)}%").join("/")} chance to redeem.";

  @override
  IconData icon = FontAwesomeIcons.dove.data;

  @override
  CityType gemType = CityType.SAMERICA;
}

// Buenos Aires — Tango: draws enemies together with a strong slow (cluster).
class Tango extends Ability {
  Tango({required super.caster, required super.level});

  static const slowPerLevel = [0.30, 0.35, 0.40, 0.45, 0.50, 0.55];

  @override
  bool get worksOnEnemies => true;

  @override
  bf.Buff? get buff => bf.SpeedModify(
        caster: caster,
        level: level,
        modifier: slowPerLevel.getByLevel(level),
        overrideBaseDuration: 2.0,
      )
        ..name = name
        ..icon = icon
        ..gemType = gemType;

  @override
  String name = "Tango";

  @override
  String description = "Draws enemies together with a powerful slow.";

  @override
  String get subDescription =>
      "${slowPerLevel.map((e) => "${(e * 100).toStringAsFixed(0)}%").join("/")} slow.";

  @override
  IconData icon = FontAwesomeIcons.personDress.data;

  @override
  CityType gemType = CityType.SAMERICA;
}

// São Paulo — Inferno: a blazing aura that burns all nearby enemies; cannot attack.
class Inferno extends Ability {
  Inferno({required super.caster, required super.level});

  @override
  bool get canAttack => false;

  @override
  bool get enemiesAura => true;

  @override
  bf.Buff? get buff => bf.Burn(caster: caster, level: level);

  @override
  String name = "Inferno";

  @override
  String description =
      "A blazing aura that burns all nearby enemies. Cannot attack.";

  @override
  String get subDescription =>
      "${bf.Burn.damagePerLevel.join("/")} damage per second.";

  @override
  IconData icon = FontAwesomeIcons.fire.data;

  @override
  CityType gemType = CityType.SAMERICA;
}

// ============================================================================
// Special abilities (used by the recipe-built special towers)
// ============================================================================

// Applies/refreshes a self damage multiplier (shared helper for the specials below).
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

// Volgograd — Mother Russia: the lower the player's capital, the more damage.
class MotherRussia extends Ability {
  MotherRussia({required super.caster, required super.level});

  @override
  GameComponent? onEnemyAttack(GemComponent gem, EnemyComponent primaryTarget,
      Set<GameComponent> targets) {
    final capital = gem.gameRef.gameStats.capital;
    final mult = 1.0 + 200.0 / (capital.abs() + 20.0);
    _applyDamageMultiplier(gem, this, mult);
    return null;
  }

  @override
  String name = "Mother Russia";

  @override
  String description = "The lower your capital, the more damage this deals.";

  @override
  String get subDescription => "Up to +1000% damage as capital runs dry.";

  @override
  IconData icon = FontAwesomeIcons.starOfLife.data;

  @override
  CityType gemType = CityType.EEUROPE;
}

// Jerusalem — Holy Land: an attack-speed aura for nearby allied cities.
class HolyLand extends Ability {
  HolyLand({required super.caster, required super.level});

  static const multipliers = [1.5, 1.7, 1.9, 2.1, 2.3, 2.5];

  @override
  bool get canAttack => false;

  @override
  bool get alliesAura => true;

  @override
  bf.Buff? get buff => bf.AttackSpeedMultiple(
        caster: caster,
        level: level,
        multipliersPerLevel: multipliers,
      )
        ..name = name
        ..icon = icon
        ..gemType = gemType;

  @override
  String name = "Holy Land";

  @override
  String description = "Greatly increases the attack speed of nearby cities.";

  @override
  String get subDescription =>
      "${multipliers.map((e) => "${e}x").join("/")} attack speed.";

  @override
  IconData icon = FontAwesomeIcons.dove.data;

  @override
  CityType gemType = CityType.MENA;
}

// Sierra Leone — Blood Diamond: huge damage + bounty, but drains capital per attack.
class BloodDiamond extends Ability {
  BloodDiamond({required super.caster, required super.level});

  static const dmgMult = [2.0, 2.3, 2.6, 2.9, 3.2, 3.5];
  static const capitalCostPerAttack = 1.0;

  @override
  bool get worksOnEnemies => true;

  @override
  bf.Buff? get buff => bf.BountyMultiple(
        caster: caster,
        level: level,
        overrideMultiplier: 2.0,
        overrideBaseDuration: 4,
      )
        ..name = name
        ..icon = icon
        ..gemType = gemType;

  @override
  GameComponent? onEnemyAttack(GemComponent gem, EnemyComponent primaryTarget,
      Set<GameComponent> targets) {
    gem.gameRef.gameStats.capital -= capitalCostPerAttack; // blood for diamonds
    _applyDamageMultiplier(gem, this, dmgMult.getByLevel(level));
    return null;
  }

  @override
  String name = "Blood Diamond";

  @override
  String description =
      "Massive damage and bounty — but drains your capital on every attack.";

  @override
  String get subDescription =>
      "${dmgMult.map((e) => "${e}x").join("/")} damage; -$capitalCostPerAttack capital per attack.";

  @override
  IconData icon = FontAwesomeIcons.gem.data;

  @override
  CityType gemType = CityType.AFRICA;
}

// Paris — Revolution: damage scales with the number of enemies in range.
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
