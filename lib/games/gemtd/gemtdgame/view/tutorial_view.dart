import 'package:flutter/material.dart';
import 'package:political_think/games/gemtd/common/constants.dart';
import 'package:political_think/games/gemtd/common/extensions.dart';
import 'package:political_think/games/gemtd/common/utils/update_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/game/game_main.dart';
import 'package:political_think/games/gemtd/gemtdgame/view/dashboard.dart';

// A skippable, step-by-step tutorial that rides along the first two real
// rounds. Steps either auto-advance when the player performs the action
// (polling live game state, same UpdateComponent pattern as Dashboard) or
// wait for NEXT on purely informational steps. SKIP is always available.
class TutorialView extends StatefulWidget {
  const TutorialView({super.key, required this.game});

  final GameMain game;

  static const String name = 'tutorial';

  @override
  State<TutorialView> createState() => _TutorialViewState();
}

class _TutStep {
  const _TutStep({
    required this.title,
    required this.body,
    this.isDone,
  });

  final String title;
  final String Function(GameMain game) body;

  // Auto-advance predicate; null means the step waits for the NEXT button.
  final bool Function(GameMain game)? isDone;
}

class _TutorialViewState extends State<TutorialView> {
  late UpdateComponent t;
  int _step = 0;

  static final List<_TutStep> _steps = [
    _TutStep(
      title: "WELCOME",
      body: (_) =>
          "Enemies march between the gates. Your countries are towers that "
          "stop them. Lose all Capital and the world ends.",
    ),
    _TutStep(
      title: "PLACE 5 COUNTRIES",
      body: (g) =>
          "Tap 5 empty tiles to place 5 random countries "
          "(${g.placeController.gemsThisRound?.length ?? 0}/5). "
          "Where you build shapes the enemies' path.",
      isDone: (g) => g.placeController.selecting,
    ),
    _TutStep(
      title: "INSPECT A TOWER",
      body: (_) =>
          "Tap one of your new countries. The bottom panel shows its level, "
          "damage, abilities and recipes.",
      isDone: (g) => Dashboard.selectedGem != null,
    ),
    _TutStep(
      title: "KEEP ONE",
      body: (_) =>
          "You keep only ONE country per round: tap ✓ on your favorite. "
          "The other four turn into blocks — walls that force enemies to "
          "walk around them.",
      isDone: (g) => g.gameStats.isWaveActive,
    ),
    _TutStep(
      title: "FIRST WAVE",
      body: (_) =>
          "The wave is marching — towers fire on their own. Every enemy that "
          "escapes costs Capital; every kill earns it. Tap an enemy to see "
          "its stats.",
      isDone: (g) => !g.gameStats.isWaveActive,
    ),
    _TutStep(
      title: "COMBINE",
      body: (_) =>
          "Round 2: place 5 more. If two IDENTICAL countries are on the "
          "board, select one and tap ↑ to combine them into a stronger "
          "level. Keep one and survive the wave.",
      isDone: (g) => g.gameStats.isWaveActive,
    ),
    _TutStep(
      title: "BLOCKS",
      body: (_) =>
          "Blocks aren't forever: while placing, DOUBLE-TAP any block to "
          "build a new country on top of it.",
    ),
    _TutStep(
      title: "SPECIAL RECIPES",
      body: (_) =>
          "Some countries fuse ACROSS regions into unique towers with wild "
          "abilities. Select a tower and tap Recipes to browse them — a + "
          "button appears when the ingredients are on the board.",
    ),
    _TutStep(
      title: "GOOD LUCK",
      body: (_) =>
          "That's everything. The waves never stop — your score is the "
          "highest Capital you ever hold. Outlast the apocalypse.",
    ),
  ];

  @override
  void initState() {
    super.initState();
    t = UpdateComponent((dt) {
      final step = _steps[_step];
      if (step.isDone != null && step.isDone!(widget.game)) {
        _advance();
      } else {
        // re-render live counters (e.g. placed x/5)
        setState(() {});
      }
    });
    widget.game.add(t);
  }

  @override
  void dispose() {
    super.dispose();
    widget.game.remove(t);
  }

  void _advance() {
    if (_step >= _steps.length - 1) {
      _close();
    } else {
      setState(() => _step++);
    }
  }

  void _close() {
    widget.game.overlays.remove(TutorialView.name);
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_step];
    final manual = step.isDone == null;
    final last = _step == _steps.length - 1;

    return Positioned(
      top: 8,
      left: 8,
      right: 8,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        decoration: BoxDecoration(
          color: context.backgroundColor.withOpacity(0.92),
          borderRadius: BRadius.least,
          border: Border.all(color: context.foregroundColorTansluscent),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    "${step.title}  ·  ${_step + 1}/${_steps.length}",
                    style: TextConstants.hackneySmall.copyWith(
                      fontSize: 12,
                      color: context.accentColor,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _close,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    child: Text(
                      "SKIP ✕",
                      style: TextStyle(
                        color: context.mutedTextColor,
                        fontSize: 11,
                        fontFamily: "Avenir",
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              step.body(widget.game),
              style: TextStyle(
                color: context.foregroundColor,
                fontSize: 13,
                fontFamily: "Avenir",
              ),
            ),
            if (manual)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: context.accentColor,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontFamily: "Avenir",
                    ),
                  ),
                  onPressed: _advance,
                  child: Text(last ? "FINISH" : "NEXT →"),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
