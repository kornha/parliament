import 'package:flame/game.dart';
import 'package:flutter/material.dart';
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
  // Whether to render the gem's buffs (true) or its abilities (false).
  static bool _showBuffs = false;

  static void resetStatic() {
    _selected = null;
    _showBuffs = false;
  }

  static void select(GemComponent? gem) {
    _selected = gem;
  }

  static show(GemComponent w, {bool showBuffs = false}) {
    _selected = w;
    _showBuffs = showBuffs;
    _selected?.gameRef.overlays.add(name);
  }

  static hide() {
    _selected?.gameRef.overlays.remove(name);
    _selected = null;
    _showBuffs = false;
  }

  static Widget builder(BuildContext context, GameMain game) {
    if (_selected == null) return const SizedBox.shrink();

    final cards = _showBuffs
        ? _selected!.buffs
            .map((b) => _DetailCard(
                  icon: b.icon,
                  color: b.color,
                  title: b.name,
                  description: b.description,
                ))
            .toList()
        : _selected!.abilities
            .map((a) => _DetailCard(
                  icon: a.icon,
                  color: a.color,
                  title: a.name,
                  description: a.description,
                  subDescription: a.subDescription,
                ))
            .toList();

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
          // Expanded keeps the panel a consistent height regardless of how
          // much (or little) ability/buff text there is.
          Expanded(
            child: gScrollView(
              scrollDirection: Axis.horizontal,
              child: SeparatedRow(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                separatorBuilder: (BuildContext context, int index) =>
                    context.sh,
                children: cards.isEmpty
                    ? [const SizedBox.shrink()]
                    : cards,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// A fixed-width card so long descriptions wrap downward (using vertical space)
// instead of stretching the card unboundedly wide. Content scrolls vertically
// if it exceeds the available height.
class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    this.subDescription,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final String? subDescription;

  static const double _width = 200;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _width,
      child: Container(
        decoration: Decorations.boxDecoration,
        padding: context.pq,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 28),
                  context.sh,
                  Expanded(
                    child: Text(
                      title,
                      style:
                          const TextStyle(color: Palette.white, fontSize: 16),
                    ),
                  ),
                ],
              ),
              context.sq,
              Text(
                description,
                style: const TextStyle(
                  color: Palette.lightSlate,
                  fontSize: 13,
                ),
              ),
              if (subDescription != null && subDescription!.isNotEmpty) ...[
                context.sq,
                Text(
                  subDescription!,
                  style: const TextStyle(
                    color: Palette.lightSlate,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
