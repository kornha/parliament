import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:political_think/games/gemtd/common/components/gem_view_container.dart';
import 'package:political_think/games/gemtd/common/components/tag.dart';
import 'package:political_think/games/gemtd/common/constants.dart';
import 'package:political_think/games/gemtd/common/extensions.dart';
import 'package:political_think/games/gemtd/gemtdgame/game/game_main.dart';
import 'package:political_think/games/gemtd/gemtdgame/view/gem_view.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gem_component.dart';
import 'package:separated_row/separated_row.dart';

class AbilityView {
  static const String name = 'expanded_gem_view';

  static GemComponent? _selected;

  static void resetStatic() {
    _selected = null;
  }

  static void select(GemComponent? gem) {
    _selected = gem;
  }

  static show(GemComponent w) {
    _selected = w;
    _selected?.gameRef.overlays.add(name);
  }

  static hide() {
    _selected?.gameRef.overlays.remove(name);
    _selected = null;
  }

  static Widget builder(BuildContext context, GameMain game) {
    var stats = game.gameController.gameRef.gameStats;
    return GemView(
      game: game,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              StatsTagTextButton(
                text: "Back",
                onPressed: () => hide(),
              )
            ],
          ),
          const Divider(color: Palette.lightSlate),
          gScrollView(
            scrollDirection: Axis.horizontal,
            child: SeparatedRow(
              mainAxisSize: MainAxisSize.min,
              separatorBuilder: (BuildContext context, int index) => context.sh,
              children: [
                ...(_selected!.abilities
                    .map(
                      (e) => Container(
                        decoration: Decorations.boxDecoration,
                        padding: context.pq,
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  e.icon,
                                  color: e.color,
                                  size: 30,
                                ),
                                context.sh,
                                Text(
                                  e.name,
                                  style: const TextStyle(
                                      color: Palette.white, fontSize: 16),
                                ),
                              ],
                            ),
                            context.sq,
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  e.description,
                                  style: const TextStyle(
                                    color: Palette.lightSlate,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            context.sq,
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  e.subDescription,
                                  style: const TextStyle(
                                    color: Palette.lightSlate,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
