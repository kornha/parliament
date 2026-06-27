import 'package:political_think/games/gemtd/gemtdgame/ability/buff.dart';
import 'package:political_think/games/gemtd/gemtdgame/base/game_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gem_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/enemy/enemy_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/game/game_controller.dart';
import 'package:political_think/games/gemtd/gemtdgame/view/dashboard.dart';
import 'package:political_think/games/gemtd/gemtdgame/view/enemy_view.dart';
import 'package:political_think/games/gemtd/gemtdgame/view/game_stats.dart';
import 'package:political_think/games/gemtd/gemtdgame/view/gem_button_view.dart';

class GameInstruction {
  GameControl instruction;
  GameComponent? source;
  GameComponent? target;

  GameInstruction(this.source, this.instruction, this.target);
  void process(GameController controller) {
    switch (instruction) {
      // case GameControl.WEAPON_SELECTED:
      //   GemView.hide();
      //   if (controller.buildingWeapon != null) {
      //     controller.queue(controller.buildingWeapon!, GameControl.TILE_TAP);
      //   }
      //   break;
      case GameControl.TILE_TAP:
        GemButtonView.hide();
        controller.gameRef.weaponFactory.tryPlaceGem(source!.position);
        break;

      case GameControl.MAP_DRAG:
        controller.gameRef.mapController.position = settings.mapPosition!;
        controller.gameRef.gameController.position = settings.mapPosition!;
        break;
      case GameControl.WEAPON_BUILD_DONE:
        // controller.buildingWeapon.buildDone = true;
        controller.gameRef.placeController.onBuildDone(source as GemComponent);
        controller.gameRef.weaponFactory.onBuildDone(source as GemComponent);
        controller.gameRef.mapController.astarMapAddObstacle(source!.position);
        controller.buildingWeapon = null;
        controller.processEnemySmartMove();
        break;
      case GameControl.GEM_CONVERTED:
        controller.gameRef.placeController
            .onGemConverted(source as GemComponent, target as GemComponent);
        if ((target as GemComponent).gemType != CityType.ROCK) {
          Dashboard.select(target as GemComponent);
        }
        (source as GemComponent).abilities.forEach((element) {
          element.onGemConverted(source as GemComponent);
        });
        break;
      case GameControl.WEAPON_DESTROYED:
        GemButtonView.hide();
        controller.gameRef.weaponFactory.onGemDestroyed(source as GemComponent);
        controller.gameRef.placeController
            .onGemDestroyed(source as GemComponent);
        controller.gameRef.mapController
            .astarMapRemoveObstacle(source!.position);
        controller.processEnemySmartMove();
        break;
      case GameControl.ENEMY_SPAWN:
        controller.gameRef.enemyFactory.start();
        break;
      case GameControl.ENEMY_MISSED:
        controller.gameRef.gameStats.onEnemyMissed(source as EnemyComponent);
        controller.gameRef.enemyFactory.onEnemyRemoved();
        Buff.onEnemyRemoved(source as EnemyComponent);
        break;
      case GameControl.ENEMY_KILLED:
        controller.gameRef.gameStats.onEnemyKilled(source as EnemyComponent);
        if (target != null) {
          (target as GemComponent).onEnemyKilled(source as EnemyComponent);
        }
        controller.gameRef.enemyFactory.onEnemyRemoved();
        Buff.onEnemyRemoved(source as EnemyComponent);

        break;
      case GameControl.ENEMY_NEXT_WAVE:
        controller.gameRef.gameStats.isWaveActive = true;
        break;
      case GameControl.WEAPON_SHOW_ACTION:
        controller.gameRef.gameController.buildingWeapon?.removeFromParent();
        GemButtonView.show(source as GemComponent);
        Dashboard.select(source as GemComponent);
        break;

      case GameControl.ENEMY_SHOW_ACTION:
        EnemyView.show(source as EnemyComponent);
        break;
      case GameControl.WAVE_COMPLETE:
        controller.gameRef.gameStats.isWaveActive = false;
        if (controller.gameRef.gameStats.wave >=
            controller.gameRef.gameStats.MAX_LEVEL) {
          controller.queue(null, GameControl.GAME_WON);
          break;
        }
        controller.queue(GameComponent(), GameControl.PLACE_START);
        Buff.onWaveComplete();
        controller.gameRef.gameStats.wave += 1;
        break;
      case GameControl.PLACE_START:
        controller.gameRef.placeController.onPlaceStart();
        break;
      case GameControl.PLACE_END:
        controller.gameRef.placeController.onPlaceEnd(source as GemComponent?);
        controller.queue(GameComponent(), GameControl.ENEMY_SPAWN);
        break;
      // case GameControl.SELECTION_START:
      //   controller.gameRef.placeController.selectionStart();
      //   break;
      // case GameControl.GEM_SELECTED:
      //   controller.gameRef.placeController
      //       .gemSelected(source as WeaponComponent);
      //   break;
      // case GameControl.SELECTION_END:
      //   break;
      case GameControl.GAME_OVER:
        controller.gameRef.overlays.add('gameover');
        controller.gameRef.pauseEngine();
        break;
      case GameControl.GAME_WON:
        controller.gameRef.overlays.add('gamewon');
        controller.gameRef.pauseEngine();
        break;
      default:
    }
  }
}
