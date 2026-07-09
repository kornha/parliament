import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:political_think/games/gemtd/common/constants.dart';
import 'package:political_think/games/gemtd/gemtdgame/base/game_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/game/game_controller.dart';
import 'package:political_think/games/gemtd/gemtdgame/game/game_constants.dart';
import 'package:political_think/games/gemtd/gemtdgame/view/dashboard.dart';

import '../enemy/enemy_component.dart';

GameConstants settings = GameConstants();

// We include drag callbacks here to eat any drag on this view
class GameStats extends GameComponent with DragCallbacks {
  GameStats()
      : super(
            position: settings.barPosition,
            size: settings.barSize,
            priority: Constants.STATS_PRIORITY) {
    active = false;
  }
  late TextComponent killedStatus;
  late TextComponent waveStatus;

  // The run is effectively endless — you play until the world ends (capital
  // hits 0). The hard stop exists only as a backstop so late-wave numbers
  // can't run away; reaching it means you outlasted the apocalypse.
  final int MAX_WAVE = 100;

  int wave = 1;
  var isWaveActive = false;

  int _killedEnemy = 0;
  int _missedEnemy = 0;

  double _capital = 10;

  // Score: the highest capital held at any point in the run.
  double maxCapital = 10;

  double get capital => _capital;
  set capital(double v) {
    _capital = v;
    if (v > maxCapital) maxCapital = v;
  }

  @override
  FutureOr<void>? onLoad() {
    waveStatus = TextComponent(
      textRenderer: TextPaint(
          style: const TextStyle(color: Colors.white70, fontSize: 22)),
      position: (size / 2),
      anchor: Anchor.center,
    );

    killedStatus = TextComponent(
      textRenderer: TextPaint(
          style: const TextStyle(color: Colors.white70, fontSize: 12)),
      position: (size / 2)..x = (size.x * (3 / 8)),
      anchor: Anchor.center,
    );

    gameRef.overlays.add(Dashboard.name);

    return super.onLoad();
  }

  int get killedEnemy => _killedEnemy;
  set killedEnemy(int n) {
    _killedEnemy = n;
    killedStatus.text = 'Killed: $_killedEnemy';
  }

  int get missedEnemy => _missedEnemy;
  set missedEnemy(int n) {
    _missedEnemy = n;
  }

  void onEnemyKilled(EnemyComponent enemy) {
    _killedEnemy++;
    capital += enemy.capital;
  }

  onEnemyMissed(EnemyComponent enemy) {
    _missedEnemy++;
    capital -= enemy.capital;
    if (capital <= 0) {
      gameRef.gameController.queue(this, GameControl.GAME_OVER);
    }
  }
}
