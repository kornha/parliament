import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:political_think/games/gemtd/common/constants.dart';
import 'package:political_think/games/gemtd/gemtdgame/ability/buff.dart';
import 'package:political_think/games/gemtd/gemtdgame/game/game_main.dart';
import 'package:political_think/games/gemtd/gemtdgame/view/ability_view.dart';
import 'package:political_think/games/gemtd/gemtdgame/view/dashboard.dart';
import 'package:political_think/games/gemtd/gemtdgame/view/enemy_view.dart';
import 'package:political_think/games/gemtd/gemtdgame/view/gem_button_view.dart';
import 'package:political_think/games/gemtd/gemtdgame/view/gem_view.dart';

/// Entry widget for the GemTD game, embedded as a Parliament tab.
///
/// This is the deferred-loading boundary: the game's code and the Flame engine
/// are only reachable through this library, so they compile into a separate
/// web chunk that is downloaded on demand when the game tab is opened.
class GemTDGame extends StatefulWidget {
  const GemTDGame({super.key});

  @override
  State<GemTDGame> createState() => _GemTDGameState();
}

class _GemTDGameState extends State<GemTDGame> {
  late GameMain _game;

  @override
  void initState() {
    super.initState();
    _game = GameMain();
  }

  void _restartGame() {
    setState(() {
      Dashboard.selectedGem = null;
      GemView.selectedGem = null;
      EnemyView.selected = null;
      GemButtonView.resetStatic();
      AbilityView.resetStatic();
      Religion.renderNumbers.clear();
      _game = GameMain();
    });
  }

  @override
  Widget build(BuildContext context) {
    // The game is laid out for a portrait phone (8x11 tile map + bottom
    // dashboard ≈ a 1:2 width:height shape). Constrain it to a centered
    // portrait box so it always receives the aspect ratio it expects, and is
    // centered (with black letterboxing) on wide/desktop screens.
    return Container(
      color: Palette.black,
      child: Center(
        child: AspectRatio(
          aspectRatio: 0.5,
          child: GameWidget<GameMain>(
            key: ObjectKey(_game),
            game: _game,
            overlayBuilderMap: {
              "${GemButtonView.name}-0": GemButtonView.builder,
              "${GemButtonView.name}-1": GemButtonView.builder,
              Dashboard.name: (context, game) => Dashboard(game: game),
              AbilityView.name: AbilityView.builder,
              EnemyView.name: (context, game) => EnemyView(game: game),
              'start': _pauseMenuBuilder,
              'gameover': _gameOverBuilder,
              'gamewon': _gameWonBuilder,
            },
            initialActiveOverlays: const ['start'],
          ),
        ),
      ),
    );
  }

  Widget _pauseMenuBuilder(BuildContext buildContext, GameMain game) {
    return Center(
        child: Container(
      width: 100,
      height: 100,
      color: Colors.orange,
      child: Center(
          child: TextButton(
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(16.0),
          textStyle: const TextStyle(fontSize: 20),
        ),
        onPressed: () {
          game.start();
          game.overlays.remove('start');
        },
        child: const Text('Start'),
      )),
    ));
  }

  Widget _gameOverBuilder(BuildContext buildContext, GameMain game) {
    return Center(
        child: Container(
      width: 100,
      height: 100,
      color: Colors.red,
      child: Center(
          child: TextButton(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.all(16.0),
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontSize: 20),
        ),
        onPressed: () {
          game.overlays.remove('gameover');
          game.resumeEngine();
          _restartGame();
        },
        child: const Text('Restart'),
      )),
    ));
  }

  Widget _gameWonBuilder(BuildContext buildContext, GameMain game) {
    return Center(
        child: Container(
      width: 100,
      height: 100,
      color: Colors.green,
      child: Center(
          child: TextButton(
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(16.0),
          textStyle: const TextStyle(fontSize: 20),
        ),
        onPressed: () {
          game.overlays.remove('gamewon');
          game.resumeEngine();
          _restartGame();
        },
        child: const Text('Restart'),
      )),
    ));
  }
}
