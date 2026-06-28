import 'dart:math';

import 'package:flame/components.dart';
import 'package:political_think/games/gemtd/gemtdgame/base/game_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/enemy/enemy_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/enemy/enemy_setting.dart';

import 'package:political_think/games/gemtd/gemtdgame/game/game_controller.dart';
import 'package:political_think/games/gemtd/gemtdgame/neutral/neutral_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gem_component.dart';

class EnemyFactory extends GameComponent {
  EnemyFactory() : super(position: Vector2.zero(), size: Vector2.zero()) {
    active = false;
    _offset = Random().nextInt(CityType.activeValues.length);
  }

  int _offset = 0;
  EnemyComponent spawnEnemey(Vector2 anchor, CityType type) {
    late EnemyComponent enemy;
    enemy = EnemyComponent(position: anchor, size: Vector2.zero())
      ..settings = EnemySettings.getEnemy(type)
    ..level = gameRef.gameStats.wave;
    return enemy;
  }

  EnemyComponent spawnOneEnemy(CityType type) {
    EnemyComponent enemy;
    Vector2 initPosition = gameRef.gameController.gateStart.position;
    enemy = spawnEnemey(initPosition, type);
    gameRef.gameController.add(enemy);
    enpowerEnemy(enemy);

    return enemy;
  }

  int _spawnCount = 0;
  int _enemiesRemaining = 0;
  double _interval = 1;

  late List<NeutralComponent> objectives = [
    gameRef.gameController.gateStart,
    gameRef.gameController.touchPoint,
    gameRef.gameController.touchPoint2,
    gameRef.gameController.gateEnd,
  ];

  void start() => nextWave();

  void nextWave() {
    gameRef.gameController.queue(this, GameControl.ENEMY_NEXT_WAVE);
    int currentWave = gameRef.gameStats.wave;

    int index = (_offset + currentWave) % CityType.activeValues.length;
    var gemType = CityType.activeValues[index];
    spawnWave(gemType);
  }

  void spawnWave(CityType gemType) {
    switch (gemType) {
      case CityType.EASIA:
        spawnEnemy(
            EnemySettings.getEnemy(gemType).spawnCount(gameRef.gameStats.wave),
            EnemySettings.getEnemy(gemType)
                .spawnInterval(gameRef.gameStats.wave),
            spawnEnemyHospitality);
        break;
      case CityType.EEUROPE:
        spawnEnemy(
            EnemySettings.getEnemy(gemType).spawnCount(gameRef.gameStats.wave),
            EnemySettings.getEnemy(gemType)
                .spawnInterval(gameRef.gameStats.wave),
            spawnEnemyEEurope);
        break;
      case CityType.NAMERICA:
        spawnEnemy(
            EnemySettings.getEnemy(gemType).spawnCount(gameRef.gameStats.wave),
            EnemySettings.getEnemy(gemType)
                .spawnInterval(gameRef.gameStats.wave),
            spawnEnemyFinance);
        break;
      case CityType.SASIA:
        spawnEnemy(
            EnemySettings.getEnemy(gemType).spawnCount(gameRef.gameStats.wave),
            EnemySettings.getEnemy(gemType)
                .spawnInterval(gameRef.gameStats.wave),
            spawnEnemySAsia);
        break;
      case CityType.ASEAN:
        spawnEnemy(
            EnemySettings.getEnemy(gemType).spawnCount(gameRef.gameStats.wave),
            EnemySettings.getEnemy(gemType)
                .spawnInterval(gameRef.gameStats.wave),
            spawnEnemyEntertainment);
        break;
      case CityType.SAMERICA:
        spawnEnemy(
            EnemySettings.getEnemy(gemType).spawnCount(gameRef.gameStats.wave),
            EnemySettings.getEnemy(gemType)
                .spawnInterval(gameRef.gameStats.wave),
            spawnEnemySAmerica);
        break;
      case CityType.MENA:
        spawnEnemy(
            EnemySettings.getEnemy(gemType).spawnCount(gameRef.gameStats.wave),
            EnemySettings.getEnemy(gemType)
                .spawnInterval(gameRef.gameStats.wave),
            spawnEnemyMena);
        break;
      case CityType.WEUROPE:
        spawnEnemy(
            EnemySettings.getEnemy(gemType).spawnCount(gameRef.gameStats.wave),
            EnemySettings.getEnemy(gemType)
                .spawnInterval(gameRef.gameStats.wave),
            spawnEnemyTech);
        break;
      case CityType.AFRICA:
        spawnEnemy(
            EnemySettings.getEnemy(gemType).spawnCount(gameRef.gameStats.wave),
            EnemySettings.getEnemy(gemType)
                .spawnInterval(gameRef.gameStats.wave),
            spawnEnemyAfrica);
        break;
      case CityType.ROCK:
        // TODO: Handle this case.
        break;
    }
  }

  void spawnEnemy(int number, double interval, Function spawnF) {
    _spawnCount = number;
    _enemiesRemaining = number;
    _interval = interval;
    spawnEnemyLoop(spawnF);
  }

  void spawnEnemyLoop(Function spawnF) {
    if (_spawnCount <= 0) {
      // add(TimerComponent(
      //     period: _interval,
      //     repeat: false,
      //     removeOnFinish: true,
      //     onTick: () => nextWave()));
      // ON SPAWN COMPLETE
    } else {
      spawnF();
      add(TimerComponent(
          period: _interval,
          repeat: false,
          removeOnFinish: true,
          onTick: () => spawnEnemyLoop(spawnF)));
      _spawnCount--;
    }
  }

  void spawnEnemyHospitality() => spawnOneEnemy(CityType.EASIA);

  void spawnEnemyEEurope() => spawnOneEnemy(CityType.EEUROPE);

  void spawnEnemyMena() => spawnOneEnemy(CityType.MENA);

  void spawnEnemySAsia() => spawnOneEnemy(CityType.SASIA);

  void spawnEnemyEntertainment() => spawnOneEnemy(CityType.ASEAN);

  void spawnEnemySAmerica() => spawnOneEnemy(CityType.SAMERICA);

  void spawnEnemyTech() => spawnOneEnemy(CityType.WEUROPE);

  void spawnEnemyFinance() => spawnOneEnemy(CityType.NAMERICA);

  void spawnEnemyAfrica() => spawnOneEnemy(CityType.AFRICA);

  void onEnemyRemoved() {
    _enemiesRemaining--;
    if (_enemiesRemaining <= 0) {
      gameRef.gameController.queue(this, GameControl.WAVE_COMPLETE);
    }
  }

  void enpowerEnemy(EnemyComponent enemy) {
    // num exp = (gameRef.gameStats.wave - 1);
    // enemy.maxLife *= math.pow(1.1, exp);
    // Must kick off enemy movement after enemy is added to game
    enemy.moveNext();
  }
}
