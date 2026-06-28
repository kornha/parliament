import 'package:flutter/material.dart';
import 'package:political_think/games/gemtd/common/components/stats_row.dart';
import 'package:political_think/games/gemtd/common/components/tag.dart';
import 'package:political_think/games/gemtd/common/constants.dart';
import 'package:political_think/games/gemtd/common/extensions.dart';
import 'package:political_think/games/gemtd/common/utils/update_component.dart';
import 'package:political_think/games/gemtd/common/utils/utils.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gem_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/game/game_constants.dart';
import 'package:political_think/games/gemtd/gemtdgame/game/game_main.dart';
import 'package:political_think/games/gemtd/gemtdgame/view/ability_view.dart';
import 'package:political_think/games/gemtd/gemtdgame/view/enemy_view.dart';
import 'package:political_think/games/gemtd/gemtdgame/view/game_stats.dart';
import 'package:political_think/games/gemtd/gemtdgame/view/gem_view.dart';
import 'package:political_think/games/gemtd/gemtdgame/view/recipes_view.dart';
import 'package:separated_column/separated_column.dart';
import 'package:separated_row/separated_row.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({
    super.key,
    required this.game,
  });

  final GameMain game;

  static const String name = 'dashboard';

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
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
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

    return GemView(game: widget.game, child: _gemView(context, stats));
  }

  Widget _gemView(BuildContext context, GameStats stats) => Column(
        children: [
          StatsRow(stats: stats),
          const Divider(color: Palette.white, thickness: 4),
          context.sq,
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  flex: 1,
                  child: Dashboard.selectedGem == null
                      ? const SizedBox.shrink()
                      : gScrollView(
                          child: SeparatedColumn(
                            separatorBuilder:
                                (BuildContext context, int index) => context.sl,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Visibility(
                                visible: Dashboard.selectedGem!.settings
                                    .countryCodes(Dashboard.selectedGem!.level)
                                    .isNotEmpty,
                                child: SeparatedRow(
                                  separatorBuilder:
                                      (BuildContext context, int index) =>
                                          context.sl,
                                  children: [
                                    ...Dashboard.selectedGem!.countryCodes
                                        .map((e) => Utils.gFlag(e))
                                  ],
                                ),
                              ),
                              Visibility(
                                  visible: Dashboard.selectedGem!.settings
                                      .countryCodes(
                                          Dashboard.selectedGem!.level)
                                      .isNotEmpty,
                                  child: context.sl),
                              StatsTag(
                                  text: "Level",
                                  subtext:
                                      Dashboard.selectedGem!.level.toString()),
                              StatsTag(
                                  text: "Bounty",
                                  subtext: Dashboard.selectedGem!.bounty
                                      .toStringAsFixed(1)),
                              StatsTag(
                                  text: "Damage",
                                  subtext: Dashboard.selectedGem!.currentDamage
                                      .toStringAsFixed(1)),
                              StatsTag(
                                text: "Rate",
                                subtext: Dashboard
                                    .selectedGem!.currentAttackSpeed
                                    .toStringAsFixed(1),
                              ),
                            ],
                          ),
                        ),
                ),
                context.sq,
                Expanded(
                  child: gScrollView(
                    child: SeparatedColumn(
                      separatorBuilder: (BuildContext context, int index) =>
                          context.sl,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          Dashboard.selectedGem?.name ?? "",
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextConstants.hackneySmall.copyWith(
                            fontSize: 13,
                          ),
                        ),
                        Image.asset(
                          "assets/images/" +
                              (Dashboard.selectedGem?.currentImagePath ??
                                  'innovation/rock.png'),
                          width: 75,
                          height: 75,
                        ),
                        Dashboard.selectedGem == null
                            ? SizedBox.shrink()
                            : Tag(type: Dashboard.selectedGem!.gemType),
                      ],
                    ),
                  ),
                ),
                context.sq,
                Expanded(
                  flex: 1,
                  child: Dashboard.selectedGem == null
                      ? const SizedBox.shrink()
                      : gScrollView(
                          child: SeparatedColumn(
                            separatorBuilder:
                                (BuildContext context, int index) => context.sl,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Dashboard.selectedGem!.abilities.isEmpty
                                  ? const SizedBox.shrink()
                                  : StatsTagButton(
                                      row: Dashboard
                                              .selectedGem!.abilities.length <
                                          2,
                                      onPressed: () {
                                        AbilityView.show(
                                            Dashboard.selectedGem!);
                                      },
                                      text: "Abilities",
                                      sub: iconGrid(Dashboard
                                          .selectedGem!.abilities
                                          .map((e) =>
                                              Icon(e.icon, color: e.color))
                                          .toList()),
                                    ),
                              Dashboard.selectedGem!.buffs.isEmpty
                                  ? const SizedBox.shrink()
                                  : StatsTagButton(
                                      row: Dashboard.selectedGem!.buffs.length <
                                          2,
                                      onPressed: () {
                                        AbilityView.show(
                                            Dashboard.selectedGem!,
                                            showBuffs: true);
                                      },
                                      text: "Buffs",
                                      sub: iconGrid(Dashboard.selectedGem!.buffs
                                          .map((e) =>
                                              Icon(e.icon, color: e.color))
                                          .toList()),
                                    ),
                              Dashboard.getRecipes().isEmpty
                                  ? const SizedBox.shrink()
                                  : StatsTagButton(
                                      row: false,
                                      onPressed: () {
                                        RecipesView.show(
                                          context,
                                          GameConstants.specialRecipes,
                                          highlight: Dashboard.getRecipes()
                                                  .keys
                                                  .isEmpty
                                              ? null
                                              : Dashboard.getRecipes()
                                                  .keys
                                                  .first,
                                        );
                                      },
                                      text: "Recipes",
                                      sub: recipeView(Dashboard.getRecipes()),
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

  // we inline 1 buff/ability so we don't return as gridview else boundry exception
  iconGrid(List<Widget> children) => children.length == 1
      ? children[0]
      : GridView.count(
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          children: children,
          shrinkWrap: true,
        );

  // Small inline preview shown on the "Recipes" button. Handles recipes of any
  // ingredient count (e.g. Volgograd has 2) — tapping opens the full browser.
  recipeView(Map<List<String>, GemComponent> recipes) {
    final cities = recipes.keys.first;
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (var i = 0; i < cities.length; i++) ...[
          Image.asset(
            "assets/images/city/${cities[i].toLowerCase()}.png",
            width: 15,
            height: 15,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const SizedBox(width: 15, height: 15),
          ),
          if (i < cities.length - 1) const Text("+"),
        ],
        //
        const Text("="),
        Image.asset(
          "assets/images/${recipes.values.first.currentImagePath}",
          width: 15,
          height: 15,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const SizedBox(width: 15, height: 15),
        ),
      ],
    );
  }
}
