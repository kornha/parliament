import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gem_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/enemy/enemy_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/game/game_constants.dart';
import 'package:political_think/games/gemtd/gemtdgame/game/game_main.dart';
import 'package:political_think/games/gemtd/gemtdgame/view/ability_view.dart';
import 'package:political_think/games/gemtd/gemtdgame/view/dashboard.dart';
import 'package:political_think/games/gemtd/gemtdgame/view/enemy_view.dart';
import 'package:political_think/games/gemtd/gemtdgame/view/gem_button_view.dart';
import 'package:political_think/games/gemtd/gemtdgame/view/tutorial_view.dart';

Future<void> step(WidgetTester tester, [int n = 1]) async {
  for (var i = 0; i < n; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 2)));
    await tester.pump(const Duration(milliseconds: 16));
  }
}

GemComponent? gemNamed(String name) {
  for (final type in CityType.activeValues) {
    for (var l = 1; l <= 6; l++) {
      final g = GameConstants.gemByType(type)..level = l;
      if (g.name == name) return GameConstants.gemByType(type)..level = l;
    }
  }
  return null;
}

/// Replays exactly what GemButtonView's special "+" button does.
void pressSpecialButton(GameMain game, GemComponent selected) {
  final specialCombinations = GameConstants.combinations(
    selected,
    game.placeController.allGems,
    GameConstants.specialRecipes,
  );
  if (specialCombinations.isEmpty) {
    throw StateError('no special combination for ${selected.name}');
  }
  selected.active = false;
  double bounty = 0.0;
  for (GemComponent g in specialCombinations.keys.first) {
    if (g != selected &&
        !(game.placeController.gemsThisRound?.contains(g) ?? false)) {
      bounty += g.bounty;
      g.downGrade();
    } else if (g == selected) {
      selected.bounty += bounty;
      selected.convertTo(specialCombinations[specialCombinations.keys.first]!);
    }
  }
}

Future<String> buildTwice(WidgetTester tester, List<String> ingredients,
    String specialName) async {
  final game = GameMain();
  Object? failure;
  await tester.pumpWidget(
    MaterialApp(
      home: GameWidget<GameMain>(
        game: game,
        overlayBuilderMap: {
          "${GemButtonView.name}-0": GemButtonView.builder,
          "${GemButtonView.name}-1": GemButtonView.builder,
          Dashboard.name: (context, g) => Dashboard(game: g),
          AbilityView.name: AbilityView.builder,
          EnemyView.name: (context, g) => EnemyView(game: g),
          TutorialView.name: (context, g) => TutorialView(game: g),
          'gameover': (c, g) => const SizedBox.shrink(),
          'gamewon': (c, g) => const SizedBox.shrink(),
        },
      ),
    ),
  );
  await step(tester, 10);
  if (!game.loadDone) return 'game did not load: ${tester.takeException()}';
  tester.takeException();

  final tile = gameSettings.mapTileSize;
  final origin = game.gameController.gateStart.position;

  for (var round = 0; round < 2; round++) {
    final placed = <GemComponent>[];
    for (var i = 0; i < ingredients.length; i++) {
      final g = gemNamed(ingredients[i]);
      if (g == null) return 'unknown ingredient ${ingredients[i]}';
      g
        ..position =
            origin + Vector2(tile.x * (i + 1), tile.y * (1 + round * 1.0))
        ..autobuild = true;
      game.gameController.add(g);
      placed.add(g);
    }
    await step(tester, 8);
    for (final g in placed) {
      game.placeController.liveGems.add(g);
    }
    tester.takeException();
    try {
      pressSpecialButton(game, placed.first);
    } catch (e, st) {
      return 'press($round): $e\n${st.toString().split("\n").take(6).join("\n")}';
    }
    await step(tester, 8);
    final ex = tester.takeException();
    if (ex != null && !ex.toString().contains('overflow')) {
      failure ??= 'after press($round): $ex';
    }
  }

  final specials = game.gameController.children
      .whereType<GemComponent>()
      .where((g) => g.name == specialName)
      .toList();

  try {
    for (final type in CityType.activeValues) {
      game.enemyFactory.spawnOneEnemy(type);
      game.enemyFactory.spawnOneEnemy(type);
    }
  } catch (e) {
    return 'spawn: $e';
  }
  for (var i = 0; i < 300; i++) {
    await step(tester);
    final ex = tester.takeException();
    if (ex != null && !ex.toString().contains('overflow')) {
      failure ??= 'combat: $ex';
      break;
    }
  }

  final diag = 'specials=${specials.length} '
      'enemies=${game.gameController.children.whereType<EnemyComponent>().length}';
  return failure == null ? 'ok [$diag]' : '$failure [$diag]';
}

void main() {
  testWidgets('build the same special twice', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final recipes = GameConstants.specialRecipes.entries.toList();
    for (final e in recipes) {
      String res;
      try {
        res = await buildTwice(tester, e.key, e.value.name);
      } catch (err, st) {
        res = 'threw: $err\n${st.toString().split("\n").take(8).join("\n")}';
      }
      // ignore: avoid_print
      print('== ${e.value.name}: $res');
    }
  });
}
