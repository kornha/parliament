import 'package:flame/components.dart';
import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:political_think/games/gemtd/common/components/buttons/gtext_button.dart';
import 'package:political_think/games/gemtd/common/constants.dart';
import 'package:political_think/games/gemtd/common/extensions.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gem_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/game/game_constants.dart';
import 'package:political_think/games/gemtd/gemtdgame/game/game_main.dart';
import 'package:separated_row/separated_row.dart';

class GemButtonView {
  static const String name = 'gembuttonview';

  static Widget builder(BuildContext context, GameMain game) {
    if (_selected == null) return const Center();

    _selected?.dialogVisible = false;

    var combinations = _selected?.gameRef.placeController.gemsThisRound == null
        ? {}
        : GameConstants.combinations(
            _selected!,
            _selected!.gameRef.placeController.gemsThisRound!,
            GameConstants.basicRecipes,
          );

    var specialCombinations = _selected == null
        ? {}
        : GameConstants.combinations(
            _selected!,
            _selected!.gameRef.placeController.allGems,
            GameConstants.specialRecipes,
          );

    var visible = [];
    if (_selected?.canDestroy() ?? false) {
      visible.add(
        GTextButton(
          color: Palette.orange,
          isActive: _selected?.canDestroy() ?? false,
          icon: FontAwesomeIcons.x.data,
          onPressed: () {
            _selected?.destroy();
            hide();
          },
        ),
      );
    }
    if ((_selected?.gameRef.placeController.selecting ?? false) &&
        (_selected?.wasPlacedThisRound ?? false)) {
      visible.add(
        GTextButton(
          color: Palette.darkGreen,
          isActive: (_selected?.gameRef.placeController.selecting ?? false) &&
              (_selected?.wasPlacedThisRound ?? false),
          icon: FontAwesomeIcons.check.data,
          onPressed: () {
            _selected?.active = false;
            _selected?.gameRef.placeController
                .onGemSelected(_selected as GemComponent);
            hide();
          },
        ),
      );
    }
    if (combinations.isNotEmpty &&
        (_selected?.gameRef.placeController.selecting ?? false)) {
      visible.add(GTextButton(
        color: Palette.navy,
        isActive: combinations.isNotEmpty,
        icon: FontAwesomeIcons.arrowUp.data,
        onPressed: () {
          _selected?.active = false;
          _selected?.convertTo(combinations[combinations.keys.first]);
          _selected?.gameRef.placeController.onGemSelected(
              combinations[combinations.keys.first] as GemComponent);
          hide();
        },
      ));
    }

    if (specialCombinations.isNotEmpty &&
        !(_selected?.gameRef.placeController.placing ?? false)) {
      visible.add(GTextButton(
        color: Palette.yellow,
        iconColor: Palette.black,
        isActive: specialCombinations.isNotEmpty,
        icon: FontAwesomeIcons.plus.data,
        onPressed: () {
          _selected?.active = false;
          double bounty = 0.0;
          for (GemComponent g in specialCombinations.keys.first) {
            // downgrade or convert all items in recipe,
            // only if items are not new, since
            // new items will be downgraded anyway
            if (g != _selected &&
                !(_selected?.gameRef.placeController.gemsThisRound
                        ?.contains(g) ??
                    false)) {
              // in this case we combine the bounty into the converted city
              bounty += g.bounty;
              g.downGrade();
            } else if (g == _selected) {
              //we set bounty here
              _selected?.bounty += bounty;
              _selected?.convertTo(
                  specialCombinations[specialCombinations.keys.first]);
            }
          }

          if ((_selected?.gameRef.placeController.selecting ?? false)) {
            if ((_selected?.wasPlacedThisRound ?? false)) {
              _selected?.gameRef.placeController.onGemSelected(
                  specialCombinations[specialCombinations.keys.first]
                      as GemComponent);
            } else {
              _selected?.gameRef.placeController.onGemSelected(null);
            }
          }
          hide();
        },
      ));
    }

    Vector2 anchor = getViewAnchor(
      context,
      game.gameController.absolutePositionOf(_selected!.position),
      _selected!.size,
      visible.length * Constants.textButtonWidth +
          (visible.length - 1) * Margins.quarter,
      Constants.textButtonHeight,
    );

    // String imagePath = "";
    // int index = 2;
    // if (index < 2) {
    //   imagePath = _selected?.settings.imagePaths[0] ?? "";
    // }

    _selected?.dialogVisible = true;

    return Positioned(
      top: anchor.y,
      left: anchor.x,
      child: Container(
        child: SeparatedRow(
          children: [
            ...visible,
          ],
          separatorBuilder: (context, index) => context.sq,
        ),
      ),
    );
  }

  static int count = 0;
  static GemComponent? _selected;

  static void resetStatic() {
    _selected = null;
    count = 0;
  }

  static show(GemComponent w) {
    hide();
    _selected = w;
    _selected?.priority = Constants.CITY_PRIORITY + 1;
    count++;
    String finalName = "$name-${count % 2}";
    _selected?.gameRef.overlays.add(finalName);
  }

  static hide() {
    _selected?.dialogVisible = false;
    _selected?.priority = Constants.CITY_PRIORITY;

    String finalName = "$name-${count % 2}";
    _selected?.gameRef.overlays.remove(finalName);
    _selected = null;
  }

  static Vector2 getViewAnchor(
    BuildContext context,
    Vector2 itemAnchor,
    Vector2 itemSize,
    double renderWidth,
    double renderHeight,
  ) {
    var anchor = itemAnchor;
    var padding = context.sq.width!;

    //left
    if (itemAnchor.x <= GameConstants().screenSize.x / 3) {
      anchor.x = itemAnchor.x - itemSize.x / 2;
    }
    // middlex
    else if (itemAnchor.x <= GameConstants().screenSize.x / 1.5) {
      anchor.x = itemAnchor.x - renderWidth / 2;
    }
    //right
    else {
      anchor.x = itemAnchor.x - renderWidth + itemSize.x / 2;
    }
    //top
    if (itemAnchor.y <= GameConstants().screenSize.y / 3) {
      anchor.y = itemAnchor.y + itemSize.y / 2 + padding;
    }
    //bottom
    else {
      anchor.y = itemAnchor.y - itemSize.y / 2 - renderHeight - padding;
    }

    return anchor;
  }
}

// class GemTypeView extends StatelessWidget {
//   final GemComponent gemComponent;

//   const GemTypeView({
//     Key? key,
//     required this.gemComponent,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//       children: [
//         Container(
//           width: 60,
//           height: 60,
//           child: Image.asset("assets/images/diag_arrow.png"),
//         ),
//         Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text("Damage: " + gemComponent.currentDamage.toString(),
//                 style: TextStyle(color: Colors.white)),
//             Text("Attack Speed: " + gemComponent.currentDamage.toString(),
//                 style: TextStyle(color: Colors.white)),
//             Text("Range: " + gemComponent.currentRange.round().toString(),
//                 style: TextStyle(color: Colors.white)),
//           ],
//         ),
//       ],
//     );
//   }
// }
