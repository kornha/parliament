import 'dart:convert';
import 'dart:math';

import 'package:flame/cache.dart';
import 'package:flame/sprite.dart';
import 'package:political_think/games/gemtd/common/utils/utils.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gem_component.dart';

import '../game/game_constants.dart';

// Roster design — every tower region uniquely counters exactly one enemy:
//   Enemy             wave/color            profile                        beats        countered by
//   Nuclear War       WEUROPE / ruby        single, fast, huge HP          NAMERICA     EASIA (stunlock)
//   Inevitability     ASEAN / aquamarine    single, very slow, very tanky  WEUROPE      EEUROPE (endless ramp)
//   Pop. Collapse     NAMERICA / opal       3 heavy high-value units       AFRICA       WEUROPE (execute)
//   Economic Collapse SAMERICA / emerald    endless mid-everything, 50% debuff resist
//                                                                          ASEAN        NAMERICA (raw burst)
//   Environment       MENA / sapphire       slow tide, sparse -> dense     WEUROPE      AFRICA (pierce line)
//   Pandemic          EASIA / gold          fast, many, negative armor     SAMERICA     MENA (auras)
//   AI                AFRICA / diamond      fastest wave, zero armor       EEUROPE      ASEAN (oil slow)
//   Radicalization    EEUROPE / amethyst    a TON, mid speed, light armor  MENA         SAMERICA (cluster+burn)
class EnemySettings {
  final double scale = 1;
  final String spritePath = "enemy/earth_opal.png";
  final int spriteRows = 4;
  final int spriteColumns = 12;
  final CityType gemType = CityType.EEUROPE;

  // Enemies are named for how they end the world, themed to their stat profile.
  String get name => "Cataclysm";

  // Fraction of incoming debuff DURATION resisted (0 = none). Applied when
  // buffs land on the enemy — stuns/slows/burns fall off early.
  double baseDebuffResistance(int level) => 0.0;

  // Waves are endless, so horde sizes must not grow unbounded — past this the
  // entity count (and per-frame radar scans) tanks the frame rate. Difficulty
  // keeps scaling through life/armor/speed instead.
  static const int maxSpawnCount = 60;

  double baseLife(int level) => 8.5 * pow(1.30, level - 1);
  double baseSpeed(int level) => 1.5 * pow(1.015, level - 1);
  double baseArmor(int level) => 1.0 * pow(1.05, level - 1);
  double baseReceiveDamageMultiplier(int level) => 1.0;
  int spawnCount(int level) => 5 + (level / 8.0).round();
  double baseCapital(int level) =>
      Utils.toDoubleCelWithPrecision(1.0 / spawnCount(level), 2) * level * 10;

  double spawnInterval(int level) => 1.0;

  // Interval before spawning unit [spawned+1] of [total]. Default is flat;
  // override for waves whose density changes as they come (see Environment).
  double spawnIntervalAt(int level, int spawned, int total) =>
      spawnInterval(level);

  // this is how we enforce static object
  // TODO: refactor to do this in the classes!
  static var enemySettings = [
    HospitalitySettings(),
    SAmericaEnemySettings(),
    //TODO(agree with Alex) should we rename TechSettings to WEuropeSettings and so on?
    TechSettings(),
    SAsiaSettings(),
    //TODO(agree with Alex) should we rename EntertainmentSettings to AseanSettings and so on?
    EntertainmentSettings(),
    FinanceSettings(),
    MenaEnemySettings(),
    EEuropeEnemySettings(),
    AfricaEnemySettings(),
  ];

  static EnemySettings getEnemy(CityType gemType) {
    switch (gemType) {
      case CityType.EASIA:
        return enemySettings[0];
      case CityType.SAMERICA:
        return enemySettings[1];
      case CityType.WEUROPE:
        return enemySettings[2];
      case CityType.SASIA:
        return enemySettings[3];
      case CityType.ASEAN:
        return enemySettings[4];
      case CityType.NAMERICA:
        return enemySettings[5];
      case CityType.MENA:
        return enemySettings[6];
      case CityType.EEUROPE:
        return enemySettings[7];
      case CityType.AFRICA:
        return enemySettings[8];
      default:
        return enemySettings[0];
    }
  }
}

// Pandemic — fast and everywhere, with NEGATIVE armor (infection makes them
// take extra damage) and a touch more health, but still weak overall.
class HospitalitySettings extends EnemySettings {
  @override
  final String spritePath = "enemy/earth_topaz.png";
  @override
  final CityType gemType = CityType.EASIA;
  @override
  double baseLife(int level) => 7.0 * pow(1.30, level - 1);
  @override
  double baseSpeed(int level) => 3.0 * pow(1.013, level - 1);
  @override
  double baseArmor(int level) => -2.0;
  @override
  int spawnCount(int level) => min(8 + level * 2, EnemySettings.maxSpawnCount);
  @override
  double spawnInterval(int level) => 0.4;

  @override
  String get name => "Pandemic";

  HospitalitySettings();
}

// Economic Collapse — it doesn't blitz, it just comes at you and doesn't end:
// mid/high speed, health and armor, debuff-resistant.
class SAmericaEnemySettings extends EnemySettings {
  @override
  final String spritePath = "enemy/earth_emerald.png";

  @override
  final CityType gemType = CityType.SAMERICA;

  @override
  double baseLife(int level) => 10.0 * pow(1.33, level - 1);
  @override
  double baseSpeed(int level) => 1.8 * pow(1.01, level - 1);
  @override
  int spawnCount(int level) => min(10 + level * 2, EnemySettings.maxSpawnCount);
  @override
  double baseArmor(int level) => 3.0 * pow(1.15, level - 1);
  @override
  double spawnInterval(int level) => 0.5;

  // Debuffs bounce off a collapsing economy — half duration.
  @override
  double baseDebuffResistance(int level) => 0.5;

  @override
  String get name => "Economic Collapse";

  SAmericaEnemySettings();
}

// Nuclear War — a single fast missile with a huge payload: one big hit to
// intercept before it crosses the board.
class TechSettings extends EnemySettings {
  @override
  final String spritePath = "enemy/earth_ruby.png";

  @override
  final CityType gemType = CityType.WEUROPE;
  @override
  double baseLife(int level) => 40.0 * pow(1.60, level - 1);
  @override
  double baseSpeed(int level) => 2.6 * pow(1.01, level - 1);

  @override
  int spawnCount(int level) => 1;

  @override
  String get name => "Nuclear War";
}

class SAsiaSettings extends EnemySettings {
  @override
  final String spritePath = "enemy/earth_emerald.png";

  @override
  final CityType gemType = CityType.SASIA;

  @override
  double baseLife(int level) => super.baseLife(level);
  @override
  double baseSpeed(int level) => 2.5 * pow(1.013, level - 1);
  @override
  int spawnCount(int level) => (super.spawnCount(level) / 1.5).ceil();
  @override
  double baseArmor(int level) => 3.2 * pow(1.25, level - 1);

  @override
  double spawnInterval(int level) => 1.2;

  // Deferred region — not in live rotation.
  @override
  String get name => "Environmental Collapse";

  SAsiaSettings();
}

// Inevitability — a single, very slow, very tanky, heavily armored unit.
// No tricks and no resistance: you simply have to out-damage it.
class EntertainmentSettings extends EnemySettings {
  @override
  final String spritePath = "enemy/earth_aquamarine.png";

  @override
  final CityType gemType = CityType.ASEAN;

  @override
  double baseLife(int level) => 70.0 * pow(1.70, level - 1);
  @override
  double baseSpeed(int level) => 0.6 * pow(1.01, level - 1);
  @override
  int spawnCount(int level) => 1;
  @override
  double baseArmor(int level) => 8.0 * pow(1.30, level - 1);

  @override
  String get name => "Inevitability";

  EntertainmentSettings();
}

class FinanceSettings extends EnemySettings {
  @override
  final String spritePath = "enemy/earth_opal.png";

  @override
  double baseLife(int level) => 20.0 * pow(1.50, level - 1);
  @override
  double baseSpeed(int level) => 1.25 * pow(1.015, level - 1);

  @override
  int spawnCount(int level) => 3;

  @override
  final CityType gemType = CityType.NAMERICA;

  // A handful of heavy, high-value threats — a demographic implosion.
  @override
  String get name => "Population Collapse";

  FinanceSettings();
}

// Environment — the tide: slower units, packed close, lots of them, some
// armor. Each wave starts sparse and gets denser as it comes.
class MenaEnemySettings extends EnemySettings {
  @override
  final String spritePath = "enemy/earth_sapphire.png";

  @override
  double baseLife(int level) => super.baseLife(level) * 0.8;
  @override
  double baseSpeed(int level) => 1.3 * pow(1.013, level - 1);
  @override
  int spawnCount(int level) => min(12 + level * 2, EnemySettings.maxSpawnCount);
  @override
  double baseArmor(int level) => 2.0 * pow(1.15, level - 1);

  // Sparse -> dense: the gap between spawns shrinks as the wave progresses.
  @override
  double spawnIntervalAt(int level, int spawned, int total) {
    final t = total <= 1 ? 1.0 : spawned / (total - 1);
    return 1.2 - (1.2 - 0.3) * t;
  }

  @override
  final CityType gemType = CityType.MENA;

  @override
  String get name => "Environment";

  MenaEnemySettings();
}

// Radicalization — a TON of them: not the fastest anymore, but far more to
// handle, with slightly more health and light armor.
class EEuropeEnemySettings extends EnemySettings {
  @override
  final String spritePath = "enemy/earth_amethyst.png";

  @override
  final CityType gemType = CityType.EEUROPE;

  @override
  double baseLife(int level) => super.baseLife(level) * 0.5;
  @override
  double baseSpeed(int level) => 2.4 * pow(1.013, level - 1);
  @override
  int spawnCount(int level) => min(14 + level * 3, EnemySettings.maxSpawnCount);
  @override
  double baseArmor(int level) => 1.0 * pow(1.1, level - 1);

  @override
  double spawnInterval(int level) => 0.3;

  @override
  String get name => "Radicalization";

  EEuropeEnemySettings();
}

// AI — the fastest wave in the game, zero armor: pure speed, nothing to slow
// it down but nothing protecting it either.
class AfricaEnemySettings extends EnemySettings {
  @override
  final String spritePath = "enemy/earth_diamond.png";

  @override
  final CityType gemType = CityType.AFRICA;

  @override
  double baseLife(int level) => super.baseLife(level) * 0.6;
  @override
  double baseSpeed(int level) => 3.6 * pow(1.013, level - 1);
  @override
  int spawnCount(int level) => min(8 + level * 2, EnemySettings.maxSpawnCount);
  @override
  double baseArmor(int level) => 0;

  @override
  double spawnInterval(int level) => 0.4;

  @override
  String get name => "AI";

  AfricaEnemySettings();
}
