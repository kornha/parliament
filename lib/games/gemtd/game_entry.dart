import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:political_think/games/gemtd/common/constants.dart';
import 'package:political_think/games/gemtd/common/extensions.dart';
import 'package:political_think/games/gemtd/common/utils/utils.dart';
import 'package:political_think/games/gemtd/gemtdgame/ability/buff.dart';
import 'package:political_think/games/gemtd/gemtdgame/game/game_main.dart';
import 'package:political_think/games/gemtd/gemtdgame/view/ability_view.dart';
import 'package:political_think/games/gemtd/gemtdgame/view/dashboard.dart';
import 'package:political_think/games/gemtd/gemtdgame/view/enemy_view.dart';
import 'package:political_think/games/gemtd/gemtdgame/view/gem_button_view.dart';
import 'package:political_think/games/gemtd/gemtdgame/view/gem_view.dart';
import 'package:political_think/games/gemtd/gemtdgame/view/tutorial_view.dart';

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
    // Keep the Flame canvas + HUD in sync with the app's light/dark theme.
    _game.canvasColor = context.backgroundColor;
    _game.hudTextColor = context.foregroundColorTansluscent;
    _game.blockColor = context.foregroundColor;

    // The game is laid out for a portrait phone (8x11 tile map + bottom
    // dashboard ≈ a 1:2 width:height shape). Constrain it to a centered
    // portrait box so it always receives the aspect ratio it expects, and is
    // centered (letterboxed in the app's background color) on wide screens.
    return Container(
      color: context.backgroundColor,
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
              TutorialView.name: (context, game) =>
                  TutorialView(game: game),
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
    return _menuCard(
      context: buildContext,
      title: 'GemTD',
      titleColor: buildContext.accentColor,
      body: const [],
      buttonLabel: 'Start',
      onPressed: () {
        game.start();
        game.overlays.remove('start');
      },
      secondaryLabel: 'Tutorial',
      onSecondary: () {
        game.start();
        game.overlays.remove('start');
        game.overlays.add(TutorialView.name);
      },
    );
  }

  Widget _gameOverBuilder(BuildContext buildContext, GameMain game) =>
      _endScreen(
        context: buildContext,
        game: game,
        overlayName: 'gameover',
        titleColor: Theme.of(buildContext).colorScheme.error,
        title: 'The World Ended',
      );

  Widget _gameWonBuilder(BuildContext buildContext, GameMain game) =>
      _endScreen(
        context: buildContext,
        game: game,
        overlayName: 'gamewon',
        titleColor: buildContext.accentColor,
        title: 'You Outlasted the Apocalypse',
      );

  // Shared end-of-run screen: the score is the highest capital held during the
  // run, alongside the wave reached.
  Widget _endScreen({
    required BuildContext context,
    required GameMain game,
    required String overlayName,
    required Color titleColor,
    required String title,
  }) {
    final stats = game.gameStats;
    return _menuCard(
      context: context,
      title: title,
      titleColor: titleColor,
      body: [
        Text(
          'Score: ${Utils.getFormattedCapital(stats.maxCapital)}',
          style: TextStyle(color: context.foregroundColor, fontSize: 16),
        ),
        Text(
          'Wave: ${stats.wave}',
          style: TextStyle(color: context.mutedTextColor, fontSize: 14),
        ),
      ],
      buttonLabel: 'Restart',
      onPressed: () {
        game.overlays.remove(overlayName);
        game.resumeEngine();
        _restartGame();
      },
    );
  }

  // Menu chrome matching the app: theme surface, thin border, Minecart title,
  // terminal-green action (plus an optional muted secondary action).
  Widget _menuCard({
    required BuildContext context,
    required String title,
    required Color titleColor,
    required List<Widget> body,
    required String buttonLabel,
    required VoidCallback onPressed,
    String? secondaryLabel,
    VoidCallback? onSecondary,
  }) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: context.backgroundColor,
          borderRadius: BRadius.standard,
          border: Border.all(color: context.foregroundColorTansluscent),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextConstants.hackneySmall.copyWith(
                color: titleColor,
                fontSize: 20,
              ),
            ),
            if (body.isNotEmpty) const SizedBox(height: 8),
            ...body,
            const SizedBox(height: 8),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: context.accentColor,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 8.0),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontFamily: "Avenir",
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BRadius.least,
                  side: BorderSide(color: context.accentColor, width: 1),
                ),
              ),
              onPressed: onPressed,
              child: Text(buttonLabel),
            ),
            if (secondaryLabel != null) ...[
              const SizedBox(height: 6),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: context.mutedTextColor,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 4.0),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontFamily: "Avenir",
                  ),
                ),
                onPressed: onSecondary,
                child: Text(secondaryLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
