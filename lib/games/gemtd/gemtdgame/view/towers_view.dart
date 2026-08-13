import 'package:flutter/material.dart';
import 'package:political_think/games/gemtd/common/extensions.dart';
import 'package:political_think/games/gemtd/common/utils/utils.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gem_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/game/game_constants.dart';

// A scrollable browser of every tower in the game: each region's level 1-6
// line plus all the cross-region specials, with their ability icons.
// Read-only reference — opened from the strip above the game.
class TowersView extends StatelessWidget {
  const TowersView({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      useRootNavigator: true,
      barrierColor: Colors.black87,
      builder: (_) => const TowersView(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sections = <Widget>[];

    for (final type in CityType.activeValues) {
      sections.add(_SectionHeader(
        label: type.name,
        color: type.color(),
      ));
      for (var l = 1; l <= 6; l++) {
        sections.add(_TowerRow(gem: GameConstants.gemByType(type)..level = l));
      }
    }

    sections.add(_SectionHeader(
      label: "SPECIALS",
      color: context.accentColor,
    ));
    final specials = GameConstants.specialRecipes.values.toList()
      ..sort((a, b) => a.level.compareTo(b.level));
    for (final special in specials) {
      sections.add(_TowerRow(gem: special));
    }

    return Dialog(
      backgroundColor: context.backgroundColor,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: context.foregroundColorTansluscent, width: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "Towers",
                      style: TextStyle(
                        color: context.foregroundColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: context.foregroundColor),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Divider(color: context.slate, height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                children: sections,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Divider(color: color.withOpacity(0.4), height: 1)),
        ],
      ),
    );
  }
}

class _TowerRow extends StatelessWidget {
  const _TowerRow({required this.gem});

  final GemComponent gem;

  @override
  Widget build(BuildContext context) {
    final abilities = gem.abilities;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: Row(
        children: [
          gem.countryCodes.isNotEmpty
              ? Utils.gFlag(gem.countryCodes.first, width: 26, height: 20)
              : const SizedBox(width: 26, height: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              gem.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: context.foregroundColor, fontSize: 13),
            ),
          ),
          Text(
            "LVL ${gem.level}",
            style: TextStyle(color: context.mutedTextColor, fontSize: 10),
          ),
          const SizedBox(width: 8),
          // Ability glyphs, colored by their region.
          ...abilities.map(
            (a) => Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Icon(a.icon, color: a.color, size: 15),
            ),
          ),
        ],
      ),
    );
  }
}
