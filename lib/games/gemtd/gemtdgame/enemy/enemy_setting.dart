import 'dart:convert';
import 'dart:math';

import 'package:flame/cache.dart';
import 'package:flame/sprite.dart';
import 'package:political_think/games/gemtd/common/utils/utils.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gem_component.dart';

import '../game/game_constants.dart';

class EnemySettings {
  final double scale = 1;
  final String spritePath = "enemy/earth_opal.png";
  final int spriteRows = 4;
  final int spriteColumns = 12;
  final CityType gemType = CityType.EEUROPE;

  // Enemies are named for how they end the world, themed to their stat profile.
  String get name => "Cataclysm";

  double baseLife(int level) => 8.5 * pow(1.30, level - 1);
  double baseSpeed(int level) => 1.5 * pow(1.015, level - 1);
  double baseArmor(int level) => 1.0 * pow(1.05, level - 1);
  double baseReceiveDamageMultiplier(int level) => 1.0;
  int spawnCount(int level) => 5 + (level / 8.0).round();
  double baseCapital(int level) =>
      Utils.toDoubleCelWithPrecision(1.0 / spawnCount(level), 2) * level * 10;

  double spawnInterval(int level) => 1.0;

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

class HospitalitySettings extends EnemySettings {
  @override
  final String spritePath = "enemy/earth_sapphire.png";
  @override
  double baseLife(int level) => 11.74 * pow(1.4, level - 1);
  @override
  double baseSpeed(int level) => 2.1 * pow(1.013, level - 1);
  @override
  int spawnCount(int level) => (super.spawnCount(level) / 2).round();
  @override
  double spawnInterval(int level) => 1.6;

  // Fast, few, and ever more virulent (steep life growth).
  @override
  String get name => "Pandemic";

  HospitalitySettings();
}

class SAmericaEnemySettings extends EnemySettings {
  @override
  final String spritePath = "enemy/earth_ruby.png";

  @override
  final CityType gemType = CityType.SAMERICA;

  @override
  double baseLife(int level) => 11.5 * pow(1.33, level - 1);
  @override
  double baseSpeed(int level) => 1.0 * pow(1.01, level - 1);
  @override
  int spawnCount(int level) => (super.spawnCount(level) * 1.75).round();
  @override
  double baseArmor(int level) => 3.00 * pow(1.1, level - 1);
  @override
  double spawnInterval(int level) => 0.3;

  // Slow, armored, and endless — a grinding wave of attrition.
  @override
  String get name => "Famine";

  SAmericaEnemySettings();
}

class TechSettings extends EnemySettings {
  @override
  final String spritePath = "enemy/earth_aquamarine.png";

  @override
  final CityType gemType = CityType.WEUROPE;
  @override
  double baseLife(int level) => 60.0 * pow(1.75, level - 1);
  @override
  double baseSpeed(int level) => 1.0 * pow(1.01, level - 1);

  int spawnCount(int level) => 1;

  // A single, catastrophic blast — one colossal, near-unkillable threat.
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

  double spawnInterval(int level) => 1.2;

  // The fastest heavy wave — a surge that overruns before you can react.
  @override
  String get name => "Environmental Collapse";

  SAsiaSettings();
}

class EntertainmentSettings extends EnemySettings {
  @override
  final String spritePath = "enemy/earth_amethyst.png";

  @override
  final CityType gemType = CityType.ASEAN;

  @override
  double baseLife(int level) => super.baseLife(level) * 0.43;
  @override
  double baseSpeed(int level) => 2.3 * pow(1.013, level - 1);
  @override
  int spawnCount(int level) => (super.spawnCount(level) * 1.8).ceil();
  @override
  double baseArmor(int level) => 6.0 * pow(1.45, level - 1);

  double spawnInterval(int level) => 0.2;

  // A dense, fast, armored swarm — individually weak, together overwhelming.
  @override
  String get name => "Pestilence";

  EntertainmentSettings();
}

class FinanceSettings extends EnemySettings {
  @override
  final String spritePath = "enemy/earth_diamond.png";

  @override
  double baseLife(int level) => 20.0 * pow(1.50, level - 1);
  @override
  double baseSpeed(int level) => 1.25 * pow(1.015, level - 1);

  int spawnCount(int level) => 3;

  @override
  final CityType gemType = CityType.NAMERICA;

  // A handful of heavy, high-value threats — a demographic implosion.
  @override
  String get name => "Population Collapse";

  FinanceSettings();
}

class MenaEnemySettings extends EnemySettings {
  @override
  final String spritePath = "enemy/earth_opal.png";

  @override
  double baseLife(int level) => super.baseLife(level) * 0.8;
  @override
  double baseSpeed(int level) => 1.75 * pow(1.013, level - 1);
  @override
  int spawnCount(int level) => 10 + level * 2;
  @override
  double baseArmor(int level) => 4.75 * pow(1.40, level - 1);

  double spawnInterval(int level) => 0.6;
  @override
  final CityType gemType = CityType.MENA;

  // A vast, hardened horde that keeps coming — a relentless, building crisis.
  @override
  String get name => "Climate Change";

  MenaEnemySettings();
}

class EEuropeEnemySettings extends EnemySettings {
  @override
  final String spritePath = "enemy/earth_topaz.png";

  @override
  final CityType gemType = CityType.EEUROPE;

  @override
  double baseLife(int level) => super.baseLife(level) * 0.40;
  @override
  double baseSpeed(int level) => 4.0 * pow(1.013, level - 1);
  @override
  int spawnCount(int level) => 10 + level * 2;
  @override
  double baseArmor(int level) => 0;

  double spawnInterval(int level) => 0.45;

  // Fragile, unarmored, but the fastest — an all-out, expendable onslaught.
  @override
  String get name => "War";

  EEuropeEnemySettings();
}

class AfricaEnemySettings extends EnemySettings {
  @override
  final String spritePath = "enemy/earth_emerald.png";

  @override
  final CityType gemType = CityType.AFRICA;

  @override
  double baseLife(int level) => super.baseLife(level) * 0.9;
  @override
  double baseSpeed(int level) => 2.0 * pow(1.013, level - 1);
  @override
  int spawnCount(int level) => 10 + level * 2;
  @override
  double baseArmor(int level) => 2.0 * pow(1.2, level - 1);

  double spawnInterval(int level) => 0.5;

  // A balanced, ever-multiplying, self-replicating swarm.
  @override
  String get name => "AI";

  AfricaEnemySettings();
}
