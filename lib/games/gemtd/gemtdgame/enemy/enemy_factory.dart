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
  int _spawnTotal = 0;
  int _enemiesRemaining = 0;
  double _interval = 1;
  EnemySettings? _spawnSettings;

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
    final Function? spawnF = switch (gemType) {
      CityType.EASIA => spawnEnemyHospitality,
      CityType.EEUROPE => spawnEnemyEEurope,
      CityType.NAMERICA => spawnEnemyFinance,
      CityType.SASIA => spawnEnemySAsia,
      CityType.ASEAN => spawnEnemyEntertainment,
      CityType.SAMERICA => spawnEnemySAmerica,
      CityType.MENA => spawnEnemyMena,
      CityType.WEUROPE => spawnEnemyTech,
      CityType.AFRICA => spawnEnemyAfrica,
      CityType.ROCK => null,
    };
    if (spawnF == null) return;

    final settings = EnemySettings.getEnemy(gemType);
    final wave = gameRef.gameStats.wave;
    spawnEnemy(
        settings.spawnCount(wave), settings.spawnInterval(wave), spawnF,
        settings);
  }

  void spawnEnemy(int number, double interval, Function spawnF,
      [EnemySettings? settings]) {
    _spawnCount = number;
    _spawnTotal = number;
    _enemiesRemaining = number;
    _interval = interval;
    _spawnSettings = settings;
    spawnEnemyLoop(spawnF);
  }

  void spawnEnemyLoop(Function spawnF) {
    if (_spawnCount <= 0) {
      // ON SPAWN COMPLETE
    } else {
      spawnF();
      // Per-spawn interval hook: lets a wave change density as it comes
      // (e.g. Environment starts sparse and gets denser).
      final spawned = _spawnTotal - _spawnCount;
      final interval = _spawnSettings?.spawnIntervalAt(
              gameRef.gameStats.wave, spawned, _spawnTotal) ??
          _interval;
      add(TimerComponent(
          period: interval,
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
