import 'package:flame/components.dart';
import 'package:flame/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:political_think/games/gemtd/common/components/gem_view_container.dart';
import 'package:political_think/games/gemtd/common/components/stats_row.dart';
import 'package:political_think/games/gemtd/common/components/tag.dart';
import 'package:political_think/games/gemtd/common/extensions.dart';
import 'package:political_think/games/gemtd/common/utils/update_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/ability/ability.dart';
import 'package:political_think/games/gemtd/gemtdgame/base/game_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/base/game_ref.dart';
import 'package:political_think/games/gemtd/gemtdgame/enemy/enemy_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/game/game_controller.dart';
import 'package:political_think/games/gemtd/gemtdgame/game/game_main.dart';
import 'package:political_think/games/gemtd/gemtdgame/game/game_constants.dart';
import 'package:political_think/games/gemtd/gemtdgame/view/ability_view.dart';
import 'package:political_think/games/gemtd/gemtdgame/view/enemy_view.dart';
import 'package:political_think/games/gemtd/gemtdgame/view/game_stats.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gem_component.dart';
import 'package:separated_column/separated_column.dart';

class GemView extends StatefulWidget {
  const GemView({
    super.key,
    required this.game,
    required this.child,
  });

  final GameMain game;
  final Widget child;

  static GemComponent? selectedGem;
  static Map<List<String>, GemComponent> getRecipes() => selectedGem == null
      ? {}
      : GameConstants.getRecipe(
          selectedGem!,
          GameConstants.specialRecipes,
        );

  static void select(GemComponent? component) {
    selectedGem = component;
    EnemyView.hide(component!.gameRef);
    AbilityView.hide();
  }

  @override
  State<GemView> createState() => _GemViewState();
}

class _GemViewState extends State<GemView> {
  //TODO: Refactor, not performant!S
  late UpdateComponent t;
  @override
  void initState() {
    super.initState();

    t = UpdateComponent((dt) {
      setState(() {});
    });

    widget.game.add(t);
  }

  @override
  void dispose() {
    super.dispose();
    widget.game.remove(t);
  }

  @override
  Widget build(BuildContext context) {
    var stats = widget.game.gameController.gameRef.gameStats;
    var screenSize = widget.game.gameController.gameRef.gameSettings.screenSize;
    var mapPosition =
        widget.game.gameController.gameRef.gameSettings.mapPosition;
    var mapSize = widget.game.gameController.gameRef.gameSettings.mapSize;
    Vector2 anchor = stats.position;
    Vector2 size = Vector2(screenSize.x, screenSize.y - mapSize.y);

    return Positioned(
      top: mapSize.y,
      child: Container(
        width: screenSize.x,
        child: GemViewContainer(
          width: size.x,
          height: size.y,
          child: widget.child,
        ),
      ),
    );
  }
}
