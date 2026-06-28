import 'package:flutter/material.dart';
import 'package:political_think/games/gemtd/common/constants.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gem_component.dart';

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

  static bool _sameRecipe(List<String> a, List<String> b) =>
      a.length == b.length && a.every(b.contains);

  @override
  void initState() {
    super.initState();
    final highlight = widget.highlight;
    if (highlight != null) {
      final keys = widget.recipes.keys.toList();
      final idx = keys.indexWhere((k) => _sameRecipe(k, highlight));
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
    final entries = widget.recipes.entries.toList();
    return Dialog(
      backgroundColor: Palette.black,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Palette.white, width: 0.5),
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
                  const Expanded(
                    child: Text(
                      "Recipes",
                      style: TextStyle(
                        color: Palette.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Palette.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(color: Palette.lightSlate, height: 1),
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

  Widget _chip(String label, String assetPath, {double size = 34}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          assetPath,
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => SizedBox(width: size, height: size),
        ),
        const SizedBox(height: 2),
        SizedBox(
          width: 58,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Palette.lightSlate, fontSize: 9),
          ),
        ),
      ],
    );
  }

  Widget _op(String s, double fontSize) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Text(s,
            style: TextStyle(color: Palette.white, fontSize: fontSize)),
      );

  @override
  Widget build(BuildContext context) {
    final desc =
        special.abilities.isNotEmpty ? special.abilities.first.description : "";

    final row = <Widget>[];
    for (var i = 0; i < cities.length; i++) {
      row.add(_chip(
        cities[i],
        "assets/images/city/${cities[i].toLowerCase()}.png",
      ));
      if (i < cities.length - 1) row.add(_op("+", 14));
    }
    row.add(_op("=", 16));
    row.add(_chip(
      special.name,
      "assets/images/${special.currentImagePath}",
      size: 42,
    ));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: highlighted ? Palette.white.withOpacity(0.08) : null,
        border: Border.all(
          color: highlighted
              ? Palette.white
              : Palette.lightSlate.withOpacity(0.4),
          width: highlighted ? 1.0 : 0.4,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: row),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              desc,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Palette.lightSlate, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
