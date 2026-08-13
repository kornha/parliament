import 'package:flutter/material.dart';
import 'package:political_think/games/gemtd/common/extensions.dart';
import 'package:political_think/games/gemtd/common/utils/utils.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gem_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/game/game_constants.dart';

// A scrollable browser of every special recipe. Opened from the "Recipes"
// button; explains each recipe (ingredient cities -> special + what it does)
// and auto-scrolls to the recipe for the currently selected gem.
class RecipesView extends StatefulWidget {
  const RecipesView({
    super.key,
    required this.recipes,
    this.highlight,
  });

  final Map<List<String>, GemComponent> recipes;
  final List<String>? highlight;

  static void show(
    BuildContext context,
    Map<List<String>, GemComponent> recipes, {
    List<String>? highlight,
  }) {
    showDialog(
      context: context,
      useRootNavigator: true,
      barrierColor: Colors.black87,
      builder: (_) => RecipesView(recipes: recipes, highlight: highlight),
    );
  }

  @override
  State<RecipesView> createState() => _RecipesViewState();
}

class _RecipesViewState extends State<RecipesView> {
  static const double _itemExtent = 150;
  final ScrollController _controller = ScrollController();

  // Recipes ordered by the resulting tower's level, low to high (stable:
  // equal levels keep their original recipe-map order).
  late final List<MapEntry<List<String>, GemComponent>> _entries;

  static bool _sameRecipe(List<String> a, List<String> b) =>
      a.length == b.length && a.every(b.contains);

  @override
  void initState() {
    super.initState();
    final raw = widget.recipes.entries.toList();
    _entries = [...raw]..sort((a, b) {
        final byLevel = a.value.level.compareTo(b.value.level);
        return byLevel != 0
            ? byLevel
            : raw.indexOf(a).compareTo(raw.indexOf(b));
      });
    final highlight = widget.highlight;
    if (highlight != null) {
      final idx = _entries.indexWhere((e) => _sameRecipe(e.key, highlight));
      if (idx > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_controller.hasClients) {
            _controller.jumpTo(
              (idx * _itemExtent).clamp(0.0, _controller.position.maxScrollExtent),
            );
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = _entries;
    return Dialog(
      backgroundColor: context.backgroundColor,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        side: BorderSide(
            color: context.foregroundColorTansluscent, width: 0.5),
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
                      "Recipes",
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
              child: ListView.builder(
                controller: _controller,
                itemExtent: _itemExtent,
                itemCount: entries.length,
                itemBuilder: (context, i) {
                  final cities = entries[i].key;
                  final special = entries[i].value;
                  final highlighted = widget.highlight != null &&
                      _sameRecipe(cities, widget.highlight!);
                  return _RecipeCard(
                    cities: cities,
                    special: special,
                    highlighted: highlighted,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({
    required this.cities,
    required this.special,
    required this.highlighted,
  });

  final List<String> cities;
  final GemComponent special;
  final bool highlighted;

  Widget _chip(BuildContext context, String label, String? code,
      {double size = 34}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Center(
            child: code == null
                ? const SizedBox.shrink()
                : Utils.gFlag(code, width: size, height: size * 3 / 4),
          ),
        ),
        const SizedBox(height: 2),
        SizedBox(
          width: 58,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: context.mutedTextColor, fontSize: 9),
          ),
        ),
      ],
    );
  }

  Widget _op(BuildContext context, String s, double fontSize) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Text(s,
            style: TextStyle(
                color: context.foregroundColor, fontSize: fontSize)),
      );

  @override
  Widget build(BuildContext context) {
    final desc =
        special.abilities.isNotEmpty ? special.abilities.first.description : "";

    final row = <Widget>[];
    for (var i = 0; i < cities.length; i++) {
      row.add(_chip(
          context, cities[i], GameConstants.countryCodeForName(cities[i])));
      if (i < cities.length - 1) row.add(_op(context, "+", 14));
    }
    row.add(_op(context, "=", 16));
    row.add(_chip(
      context,
      special.name,
      special.countryCodes.isNotEmpty ? special.countryCodes.first : null,
      size: 42,
    ));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: highlighted
            ? context.accentColor.withOpacity(0.08)
            : null,
        border: Border.all(
          color: highlighted
              ? context.accentColor
              : context.slate.withOpacity(0.4),
          width: highlighted ? 1.0 : 0.4,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: row),
                ),
              ),
              Text(
                "LVL ${special.level}",
                style: TextStyle(color: context.mutedTextColor, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              desc,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: context.mutedTextColor, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
