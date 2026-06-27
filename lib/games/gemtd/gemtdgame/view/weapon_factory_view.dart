import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:political_think/games/gemtd/gemtdgame/base/game_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/game/game_controller.dart';
import 'package:political_think/games/gemtd/gemtdgame/game/game_constants.dart';
import 'package:political_think/games/gemtd/gemtdgame/view/mine_view.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gems/rock.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gems/asean/asean.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gems/easia/easia.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gem_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gems/special_companies/coinbase.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gems/special_companies/hard_rock.dart';

GameConstants gameSetting = GameConstants();

class WeaponFactoryView extends GameComponent {
  WeaponFactoryView()
      : super(
            position: Vector2(
                gameSetting.viewSize.x * (1 / 3), gameSetting.viewPosition.y),
            size: Vector2(
                gameSetting.viewSize.x * (2 / 3) - gameSetting.mapTileSize.x,
                gameSetting.viewSize.y * (2 / 3)));

  int onBuildDone(GemComponent c) {
    return 0;
  }

  int onGemDestroyed(GemComponent c) {
    return 0;
  }

  placeGem(GemComponent gem) async {
    gem.unhide();
    gameRef.gameController.queue(gem, GameControl.WEAPON_BUILD_DONE);
    gem.onBuildDone();
  }

  onGemSelected(GemComponent gem) {
    if (gem.buildDone == false) {
      if (gem.buildAllowed) {
        placeGem(gem);
      }
    } else {
      if (active) {
        gameRef.gameController.queue(gem, GameControl.WEAPON_SHOW_ACTION);
      } else {
        // return true;
        // gameRef.gameController.send(this, GameControl.WEAPON_SHOW_PROFILE);
      }
    }
  }

  static const _testGem =
      String.fromEnvironment('TEST_GEM', defaultValue: '');

  GemComponent getNextGem() {
    if (_testGem.isNotEmpty) {
      return GameConstants.gemByType(CityType.values.byName(_testGem))
        ..level = 1;
    }
    int level = GameConstants.caclculateLevel(
        gameRef.scoreController.level, Random().nextDouble());
    return GameConstants.randomGem()..level = level;
  }

  tryPlaceGem(Vector2 anchor) {
    if (gameRef.placeController.placing) {
      // Before adding a new unconfirmed gem ensure that the position is free.
      // Sometimes it's possible to tap on a cell for placing a gem too fast,
      // and without the check at the same position could be added 2 unconfirmed
      // gems that will cause an error when start a new wave and game won't play.
      if (!hasGemAtPosition(anchor)) {
        GemComponent component = getNextGem()
          ..position = anchor
          ..hideSprite = true;
        placeUnconfirmedGem(component);
      }
    }
  }

  bool hasGemAtPosition(Vector2 anchor) =>
      gameRef.gameController.children
          .whereType<GemComponent>()
          .any((child) => child.position == anchor);


  placeUnconfirmedGem(GemComponent component) {
    gameRef.gameController.add(component);
    gameRef.gameController.buildingWeapon?.removeFromParent();
    gameRef.gameController.buildingWeapon = component;
    component.blockMap = gameRef.enemyFactory.objectives
            .any((element) => component.collision(element)) ||
        gameRef.gameController.gameRef.mapController
            .testBlock(component.position);
  }
}
