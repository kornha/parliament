import 'package:flame/cache.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame/sprite.dart';
import 'package:flame/widgets.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:political_think/games/gemtd/common/components/gem_view_container.dart';
import 'package:political_think/games/gemtd/common/components/stats_row.dart';
import 'package:political_think/games/gemtd/common/components/tag.dart';
import 'package:political_think/games/gemtd/common/constants.dart';
import 'package:political_think/games/gemtd/common/extensions.dart';
import 'package:political_think/games/gemtd/common/utils/update_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/enemy/enemy_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/game/game_main.dart';
import 'package:political_think/games/gemtd/gemtdgame/view/dashboard.dart';
import 'package:political_think/games/gemtd/gemtdgame/view/gem_view.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gem_component.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:separated_column/separated_column.dart';
import 'package:separated_row/separated_row.dart';

import 'game_stats.dart';

class EnemyView extends StatefulWidget {
  const EnemyView({super.key, required this.game});

  final GameMain game;
  static const String name = 'enemy_view';

  static EnemyComponent? selected;

  static show(EnemyComponent w) {
    selected = w;
    if (selected?.active ?? false) {
      selected?.gameRef.overlays.add(name);
    }
  }

  // need to pass in ref since the enemy maybe be
  // removed from parent
  static hide(GameMain gameRef) {
    gameRef.overlays.remove(name);
    selected = null;
  }

  @override
  State<EnemyView> createState() => _EnemyViewState();
}

class _EnemyViewState extends State<EnemyView> {
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
    return GemView(game: widget.game, child: _enemyView(context, stats));
  }

  //TODO: Refactor
  Widget _enemyView(BuildContext context, GameStats stats) {
    return Column(
      children: [
        StatsRow(stats: stats),
        const Divider(color: Palette.white, thickness: 4),
        context.sq,
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                flex: 1,
                child: EnemyView.selected == null
                    ? SizedBox.shrink()
                    : gScrollView(
                        child: SeparatedColumn(
                          separatorBuilder: (BuildContext context, int index) =>
                              context.sl,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            StatsTag(
                                text: "Level",
                                subtext: EnemyView.selected!.level.toString()),
                            StatsTag(
                                text: "Speed",
                                subtext: EnemyView.selected!.speed
                                    .toStringAsFixed(1)),
                            StatsTag(
                              text: "Max",
                              subtext: EnemyView.selected!.maxLife
                                  .toStringAsFixed(1),
                            ),
                            StatsTag(
                              text: "Capital",
                              subtext: EnemyView.selected!.capital
                                  .toStringAsFixed(2),
                            ),
                            StatsTag(
                              text: "Armor",
                              subtext:
                                  EnemyView.selected!.armor.toStringAsFixed(1),
                            ),
                          ],
                        ),
                      ),
              ),
              Expanded(
                child: gScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        EnemyView.selected?.settings.name ?? "",
                        style: TextConstants.hackneySmall,
                      ),
                      context.sq,
                      EnemyView.selected == null
                          ? const SizedBox.shrink()
                          : SizedBox(
                              width: 72,
                              height: 72,
                              child: CircularPercentIndicator(
                                animationDuration: 20,
                                radius: 35,
                                backgroundColor: Palette.darkSlate,
                                percent: EnemyView.selected!.life < 0
                                    ? 0
                                    : EnemyView.selected!.life /
                                        EnemyView.selected!.maxLife,
                                center: Text(
                                    EnemyView.selected!.life < 0
                                        ? "Sold"
                                        : ((EnemyView.selected!.life /
                                                        EnemyView.selected!
                                                            .maxLife) *
                                                    100)
                                                .toStringAsFixed(0) +
                                            "%",
                                    style: TextStyle(color: Colors.white)),
                                progressColor: EnemyView
                                    .selected!.settings.gemType
                                    .color(),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: EnemyView.selected == null
                    ? const SizedBox.shrink()
                    : gScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            EnemyView.selected!.buffs.isEmpty
                                ? const SizedBox.shrink()
                                : StatsTagButton(
                                    row: EnemyView.selected!.buffs.length < 2,
                                    onPressed: () {},
                                    text: "Buffs",
                                    sub: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      mainAxisSize: MainAxisSize.max,
                                      children: EnemyView.selected!.buffs
                                          .map((e) =>
                                              Icon(e.icon, color: e.color))
                                          .toList(),
                                    ),
                                  ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
