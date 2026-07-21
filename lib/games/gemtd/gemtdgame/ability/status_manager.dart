import 'package:political_think/games/gemtd/gemtdgame/ability/buff.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gem_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/enemy/enemy_component.dart';

// class to compute stats when scaled by buffs AND abilities

class StatusManager {
  // **************
  // Buff only, since only buffs are time bound
  // **************

  static void tick(dt, Set<Buff> buffs) {
    buffs.removeWhere((buff) {
      if (buff.duration == null) return false;
      // Only decrement tick durations
      // attack durations decrement on enemy attack
      if (buff.durationType == DurationType.TICK) {
        buff.duration = buff.duration! - dt;
      }
      // we can remove any duration type here, doesn't matter if attack
      if (buff.duration! <= 0) {
        return true;
      }
      return false;
    });
  }

  //ticks after an attack for durations that are a # of attacks
  static void tickAttack(
    Set<Buff> buffs,
  ) {
    buffs.removeWhere((buff) {
      if (buff.duration == null) return false;
      if (buff.durationType == DurationType.ATTACK) {
        buff.duration = buff.duration! - 1;
        if (buff.duration! <= 0) {
          return true;
        }
      }
      return false;
    });
  }

  static void tickGem(
    dt,
    GemComponent gem,
    Set<Buff> buffs,
  ) {
    tick(dt, buffs);
    StatusManager.computeGemStatus(buffs, gem);
  }

  static void computeGemStatus(
    Set<Buff> buffs,
    GemComponent gem,
  ) {
    // Propaganda (Qatar): a buff may override the effective tier used to scale
    // base stats (homogenizing nearby allies up or down to Qatar's level).
    var effectiveLevel = gem.level;
    for (var buff in buffs) {
      final lvl = buff.levelOverride;
      if (lvl != null) effectiveLevel = lvl;
    }
    var tempRange = gem.settings.baseRange(effectiveLevel);
    var tempDamage = gem.settings.baseDamage(effectiveLevel);
    var tempAttackSpeed = gem.settings.baseAttackSpeed(effectiveLevel);
    var tempBountyMultiplier = 1.0;
    var tempBuffMultiplier = 1.0;
    var tempChanceMultiplier = 1.0;
    var tempBountyDamageScalar = 1.0;
    //
    // double? tempChanceOverride = null;
    // non-ability or debuffs

    for (var buff in buffs) {
      tempBuffMultiplier *= buff.buffMultiplier ?? 1.0;
    }

    // gem fields
    for (var buff in buffs) {
      //
      tempRange +=
          buff.rangeDelta == null ? 0 : buff.rangeDelta! * tempBuffMultiplier;
      //
      tempRange *= buff.rangeMultiplier == null
          ? 1
          : buff.rangeMultiplier! * tempBuffMultiplier;
      //
      if (buff is LeningradBuff) {
        var casterDamage = buff.caster.currentDamage;
        if (tempDamage < casterDamage) {
          tempDamage = casterDamage;
        }
      } else {
        tempDamage *= buff.damageMultiplier == null
            ? 1
            : buff.damageMultiplier! * tempBuffMultiplier;
      }
      //
      tempAttackSpeed *= buff.attackSpeedMultiplier == null
          ? 1
          : buff.attackSpeedMultiplier! * tempBuffMultiplier;
      //
      tempBountyMultiplier *= buff.bountyMultiplier == null
          ? 1
          : (1.0 + buff.bountyMultiplier!) * tempBuffMultiplier;
      //
      tempChanceMultiplier *= buff.chanceMultiplier == null
          ? 1
          : buff.chanceMultiplier! * tempBuffMultiplier;
      //
      tempBountyDamageScalar *= buff.bountyDamageScalar == null
          ? 1
          : buff.bountyDamageScalar! * tempBuffMultiplier;
      // removed overrides in favor of multipler
      // tempChanceOverride = tempChanceOverride == null
      //     ? buff.chanceOverride
      //     : max(tempChanceOverride, buff.chanceOverride ?? 0.0);
    }

    // bounty-to-damage scaling (amplified by Startup Nation)
    tempDamage *= 1 + gem.bounty / 100 * tempBountyDamageScalar;

    // ability/buff on ability overrides here
    gem.abilities.forEach((ability) {
      if (ability.baseChance != null) {
        ability.currentChance = tempChanceMultiplier * ability.baseChance!;
        if (ability.currentChance! > 1.0) ability.currentChance = 1;
      }
    });

    gem.currentBuffMultiplier = tempBuffMultiplier;
    gem.currentDamage = tempDamage;
    gem.currentRange = tempRange;
    gem.currentAttackSpeed = tempAttackSpeed;
    gem.currentBountyMultiplier = tempBountyMultiplier;
  }

  static void tickEnemy(
    dt,
    EnemyComponent enemy,
    Set<Buff> buffs,
  ) {
    // Myanmar's Timeless aura: while marked, the enemy's debuffs do not
    // decay — only the marker itself ticks, so leaving the aura frees them.
    final frozen = buffs.any((b) => b is TimelessBuff);
    if (frozen) {
      final markers = buffs.whereType<TimelessBuff>().toSet();
      tick(dt, markers);
      buffs.removeWhere(
          (b) => b is TimelessBuff && !markers.contains(b));
    } else {
      tick(dt, buffs);
    }
    StatusManager.computeEnemyStatus(dt, buffs, enemy);
  }

  // computes buffs to the enemy (no abilities yet on enemies), but damage buffs are only applied on tick
  // we do this so slows and armor reduce takes place before damage is applied
  static void computeEnemyStatus(
    double? dt,
    Set<Buff> buffs,
    EnemyComponent enemy,
  ) {
    var tempSpeed = enemy.settings.baseSpeed(enemy.level);
    var tempArmor = enemy.settings.baseArmor(enemy.level);
    var tempCapital = enemy.settings.baseCapital(enemy.level);
    var tempReceiveDamageMultiplier =
        enemy.settings.baseReceiveDamageMultiplier(enemy.level);

    for (var buff in buffs) {
      // stops infinite loop when dt is null since receive damage recomputes
      if (dt != null && buff.damage != null) {
        var deltaDamage = buff.damage! * dt * buff.caster.currentBuffMultiplier;
        enemy.receiveDamage(deltaDamage, {}, buff.caster);
        if (buff is Religion) {
          Religion.renderNumbers.update(
            enemy,
            // You can ignore the incoming parameter if you want to always update the value even if it is already in the map
            (existingValue) => existingValue + deltaDamage,
            ifAbsent: () => deltaDamage,
          );
        }
      } else if (dt != null && buff is UprisingBuff) {
        var deltaDamage =
            buff.damageForEnemy(enemy) * dt * buff.caster.currentBuffMultiplier;
        enemy.receiveDamage(deltaDamage, {}, buff.caster);
      }

      final speedModifier = buff.speedModifier(enemy);
      if (speedModifier != null) {
        tempSpeed = tempSpeed * (1 - speedModifier * (buff.stacks ?? 1));
      }
      //
      final armorModifier = buff.armorModifier(enemy);
      if (armorModifier != null) {
        tempArmor -= armorModifier *
            (buff.stacks ?? 1) *
            buff.caster.currentBuffMultiplier;
      }
      //
      final bountyMultiplier = buff.bountyMultiplier;
      if (bountyMultiplier != null) {
        tempCapital *= (1.0 + bountyMultiplier * (buff.stacks ?? 1)) *
            buff.caster.currentBuffMultiplier;
      }
      //
      final receiveDamageMultiplier = buff.receiveDamageMultiplier(enemy);
      if (receiveDamageMultiplier != null) {
        tempReceiveDamageMultiplier *=
            1.0 + receiveDamageMultiplier * (buff.stacks ?? 1);
      }
    }

    // Clamp speed to realistic boundaries: below 0 an enemy walks backwards
    // off the map (over-stacked slows); above ~6.5 movement visibly breaks
    // (relevant now that waves are endless and base speed grows exponentially).
    enemy.speed = tempSpeed.clamp(0.0, 6.5);
    enemy.armor = tempArmor;
    enemy.capital = tempCapital;
    enemy.receiveDamageMultiplier = tempReceiveDamageMultiplier;
  }
}
