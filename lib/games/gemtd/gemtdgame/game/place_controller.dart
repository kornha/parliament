import 'package:political_think/games/gemtd/gemtdgame/base/game_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/game/game_controller.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gems/rock.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gems/asean/asean.dart';

import '../cities/gem_component.dart';

class PlaceController extends GameComponent {
  bool get placing => gemsThisRound != null && gemsThisRound!.length < 5;
  bool get selecting => gemsThisRound != null && gemsThisRound!.length == 5;
  bool get placeOver => !selecting && !placing;
  List<GemComponent>? gemsThisRound;
  List<GemComponent> liveGems = [];
  List<GemComponent> get allGems => [...liveGems, ...?gemsThisRound];

  void onPlaceStart() {
    gemsThisRound = [];
    gameRef.scoreController.level++;
  }

  void onPlaceEnd(GemComponent? kept) {
    for (GemComponent g in gemsThisRound!) {
      if (g != kept) {
        g.downGrade();
      }
    }
    gemsThisRound = null;
    if (kept != null) {
      liveGems.add(kept);
    }
  }

  void onGemDestroyed(GemComponent gem) {
    liveGems.remove(gem);
  }

  void onGemConverted(GemComponent source, GemComponent target) {
    // removes only if gem is live, if selecting noop

    if (gemsThisRound?.contains(source) ?? false) {
      gemsThisRound?.remove(source);
      if (target is! Rock) {
        gemsThisRound?.add(target);
      }
    }
    //
    if (liveGems.contains(source)) {
      liveGems.remove(source);
      if (target is! Rock) {
        liveGems.add(target);
      }
    }
  }

  void onGemSelected(GemComponent? kept) async {
    gameRef.gameController.queue(kept, GameControl.PLACE_END);
  }

  onBuildDone(GemComponent gem) {
    if (placing) {
      gemsThisRound!.add(gem);
    } else {
      liveGems.add(gem);
    }
  }
}
