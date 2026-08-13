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

Future<String> runScenario(
  WidgetTester tester,
  String label,
  int copies,
  GemComponent Function() make,
) async {
  final game = GameMain();
  Object? failure;
  await tester.pumpWidget(
    MaterialApp(
      home: SizedBox(
        width: 400,
        height: 800,
        child: GameWidget<GameMain>(
          game: game,
          overlayBuilderMap: {
            "${GemButtonView.name}-0": (c, g) => const SizedBox.shrink(),
            "${GemButtonView.name}-1": (c, g) => const SizedBox.shrink(),
            Dashboard.name: (context, g) => const SizedBox.shrink(),
            AbilityView.name: (c, g) => const SizedBox.shrink(),
            EnemyView.name: (context, g) => const SizedBox.shrink(),
            TutorialView.name: (context, g) => const SizedBox.shrink(),
            'gameover': (c, g) => const SizedBox.shrink(),
            'gamewon': (c, g) => const SizedBox.shrink(),
          },
        ),
      ),
    ),
  );
  await step(tester, 10);
  if (!game.loadDone) return 'game did not load: ${tester.takeException()}';
  failure ??= tester.takeException();

  final start = game.gameController.gateStart.position;
  final tile = gameSettings.mapTileSize;

  for (var i = 0; i < copies; i++) {
    final g = make()
      ..position = start + Vector2(tile.x * 0.9 * (i + 1), tile.y * 0.4)
      ..autobuild = true;
    game.gameController.add(g);
  }
  await step(tester, 10);
  failure ??= tester.takeException();

  try {
    for (final type in CityType.activeValues) {
      game.enemyFactory.spawnOneEnemy(type);
      game.enemyFactory.spawnOneEnemy(type);
    }
  } catch (e) {
    return 'spawn: $e';
  }

  for (var i = 0; i < 400; i++) {
    await step(tester);
    final ex = tester.takeException();
    if (ex != null) {
      failure ??= ex;
      break;
    }
  }
  final gems = game.gameController.children.whereType<GemComponent>().toList();
  final diag = 'gems=${gems.length} '
      'built=${gems.where((g) => g.buildDone).length} '
      'fires=${gems.fold<int>(0, (a, g) => a + g.fireCount)} '
      'enemies=${game.gameController.children.whereType<EnemyComponent>().length}';
  return failure == null ? 'ok [$diag]' : '$failure [$diag]';
}

void main() {
  testWidgets('duplicate specials live run', (tester) async {
    final protos = <String, GemComponent Function()>{};
    for (final proto in GameConstants.specialRecipes.values.toList()) {
      protos[proto.name] = () => proto.equivalentGem();
    }
    for (final entry in protos.entries) {
      String one;
      String two;
      try {
        one = await runScenario(tester, entry.key, 1, entry.value);
      } catch (e) {
        one = 'threw: $e';
      }
      try {
        two = await runScenario(tester, entry.key, 2, entry.value);
      } catch (e) {
        two = 'threw: $e';
      }
      // ignore: avoid_print
      print("== ${entry.key}\n   x1: $one\n   x2: $two");
    }
  });
}
