import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:political_think/games/gemtd/gemtdgame/base/game_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/enemy/enemy_factory.dart';
import 'package:political_think/games/gemtd/gemtdgame/game/game_constants.dart';
import 'package:political_think/games/gemtd/gemtdgame/game/game_controller.dart';
import 'package:political_think/games/gemtd/gemtdgame/game/place_controller.dart';
import 'package:political_think/games/gemtd/gemtdgame/game/score_controller.dart';
import 'package:political_think/games/gemtd/gemtdgame/map/map_controller.dart';
import 'package:political_think/games/gemtd/gemtdgame/view/game_stats.dart';
import 'package:political_think/games/gemtd/gemtdgame/view/weapon_factory_view.dart';

class GameMain extends FlameGame with WidgetsBindingObserver {
  late MapController mapController;
  late GameController gameController;
  late PlaceController placeController;
  late ScoreController scoreController;
  late WeaponFactoryView weaponFactory;
  late EnemyFactory enemyFactory;
  late GameStats gameStats;

  // Set from GemTDGame.build so the canvas + HUD text match the app's
  // light/dark theme (Flame repaints backgroundColor every frame, so theme
  // switches take effect live).
  // Default matches the app's dark surface so the first frame (before
  // GemTDGame.build assigns the live theme color) doesn't flash pure black.
  Color canvasColor = const Color(0xFF0E0E0E);
  Color hudTextColor = Colors.white70;

  // Rocks tint to this (the sprite is a white block, so light mode needs
  // black blocks to stay visible on the white canvas).
  Color blockColor = const Color(0xFFFFFFFF);

  @override
  Color backgroundColor() => canvasColor;

  bool started = false;
  bool loadDone = false;

  GameConstants gameSettings = GameConstants();

  GameMain() {
    // do we need to dispose this?
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Pause game logic here
      gameController.gameRef.pauseEngine();
    } else if (state == AppLifecycleState.resumed) {
      // Resume game logic here
      gameController.gameRef.resumeEngine();
    } else {}
  }

  @override
  void onGameResize(Vector2 canvasSize) {
    if (!loadDone) settings.setScreenSize(canvasSize);
    super.onGameResize(canvasSize);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    await settings.neutral.load();

    mapController = MapController(
      tileSize: settings.mapTileSize,
      mapGrid: settings.mapGrid,
      position: settings.mapPosition,
      size: settings.mapSize,
    );

    /*game controller should have same range as map */
    gameController =
        GameController(position: settings.mapPosition, size: settings.mapSize);

    gameStats = GameStats();
    weaponFactory = WeaponFactoryView();
    scoreController = ScoreController();
    placeController = PlaceController();
    enemyFactory = EnemyFactory();

    // await settings.weapons.load(gameSettings);

    add(mapController);
    add(gameController);
    add(gameStats);
    add(weaponFactory);
    add(placeController);
    add(enemyFactory);

    // settings.enemies.load();

    loadDone = true;
  }

  @override
  void onRemove() {
    WidgetsBinding.instance.removeObserver(this);
    super.onRemove();
  }

  @override
  void update(double t) {
    super.update(t);
  }

  void start() {
    if (loadDone) {
      gameController.queue(GameComponent(), GameControl.PLACE_START);
    }
  }
}
