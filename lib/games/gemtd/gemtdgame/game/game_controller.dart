import 'dart:collection';

import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:political_think/games/gemtd/common/constants.dart';
import 'package:political_think/games/gemtd/gemtdgame/base/game_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/base/radar.dart';
import 'package:political_think/games/gemtd/gemtdgame/base/scanable.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gem_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/enemy/enemy_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/game/game_constants.dart';
import 'package:political_think/games/gemtd/gemtdgame/game/game_instruction.dart';
import 'package:political_think/games/gemtd/gemtdgame/neutral/neutral_component.dart';

GameConstants gameConst = GameConstants();

// ignore_for_file: constant_identifier_names
enum GameControl {
  TILE_TAP,
  MAP_DRAG,
  WEAPON_SELECTED,
  WEAPON_BUILD_DONE,
  WEAPON_DESTROYED,
  GEM_CONVERTED,
  WEAPON_SHOW_ACTION,
  WEAPON_SHOW_PROFILE,
  ENEMY_SPAWN,
  ENEMY_MISSED,
  ENEMY_KILLED,
  ENEMY_SHOW_ACTION,
  ENEMY_NEXT_WAVE,
  WAVE_COMPLETE,
  PLACE_START,
  PLACE_END,
  // SELECTION_START,
  // GEM_SELECTED,
  // SELECTION_END,
  GAME_OVER,
  GAME_WON
}

class GameController extends GameComponent {
  // with DragCallbacks
  GemComponent? buildingWeapon;
  GameController({
    position,
    size,
  }) : super(
            position: position,
            size: size,
            priority: Constants.GAME_PRIORITY) {}

  @override
  void update(double dt) {
    processInstruction();
    processRadarScan();
    super.update(dt);
  }

  /* Instruction Queue*/
  final Queue _instructQ = Queue<GameInstruction>();
  queue(
    GameComponent? source,
    GameControl instruct, [
    GameComponent? target,
  ]) {
    _instructQ.add(GameInstruction(source, instruct, target));
  }

  void processInstruction() {
    while (_instructQ.isNotEmpty) {
      GameInstruction instruct = _instructQ.removeFirst();
      instruct.process(this);
    }
  }

  /* Process Routine */
  // do we need to dt this??
  void processRadarScan() {
    Iterable<Component> radars =
        children.where((e) => e is Radar && e.radarOn).cast();
    Iterable<Component> scanbles =
        children.where((e) => e is Scanable && e.scanable).cast();

    radars.forEach((element) {
      (element as Radar).radarScan(scanbles);
    });
  }

  void processEnemySmartMove() {
    Iterable<Component> enemies =
        children.where((e) => e is EnemyComponent && e.active).cast();
    enemies.forEach((element) {
      (element as EnemyComponent).moveNext();
    });
  }

  /* Load Initialization */
  late NeutralComponent gateStart;
  late NeutralComponent gateEnd;
  late NeutralComponent touchPoint;
  late NeutralComponent touchPoint2;

  @override
  Future<void>? onLoad() {
    super.onLoad();
    loadGates();
    return null;
  }

  void loadGates() async {
    Vector2 start = Vector2(0, 0);
    Vector2 end = Vector2(0, gameConst.mapGrid.y - 1);

    start = gameConst.dotMultiple(start, gameConst.mapTileSize) +
        (gameConst.mapTileSize / 2);
    end = gameConst.dotMultiple(end, gameConst.mapTileSize) +
        (gameConst.mapTileSize / 2);

    final images = Images();
    gateStart = NeutralComponent(
        position: gameConst.dotMultiple(Vector2(0, 0), gameConst.mapTileSize) +
            (gameConst.mapTileSize / 2),
        size: gameConst.mapTileSize,
        neutralType: NeutralType.GATE_START)
      ..sprite = Sprite(
        await images.load('weapon/right.png'),
      );

    touchPoint = NeutralComponent(
        position: gameConst.dotMultiple(
                Vector2((gameConst.mapGrid.x - 1), 0), gameConst.mapTileSize) +
            (gameConst.mapTileSize / 2),
        size: gameConst.mapTileSize,
        neutralType: NeutralType.TOUCH)
      ..sprite = Sprite(
        await images.load('weapon/down.png'),
      );

    touchPoint2 = NeutralComponent(
        position: gameConst.dotMultiple(
                Vector2(gameConst.mapGrid.x - 1, gameConst.mapGrid.y - 1),
                gameConst.mapTileSize) +
            (gameConst.mapTileSize / 2),
        size: gameConst.mapTileSize,
        neutralType: NeutralType.TOUCH)
      ..sprite = Sprite(
        await images.load('weapon/left.png'),
      );

    gateEnd = NeutralComponent(
        position: end,
        size: gameConst.mapTileSize,
        neutralType: NeutralType.GATE_END)
      ..sprite = Sprite(
        await images.load('weapon/cross.png'),
      );

    add(gateStart);
    add(touchPoint);
    add(touchPoint2);
    add(gateEnd);
  }

  // @override
  // void onDragStart(DragStartEvent event) {
  //   // final trail = Trail(event.localPosition);
  //   // _trails[event.pointerId] = trail;
  //   // add(trail);
  //   print("start event");
  //   print(event);
  // }

  // @override
  // void onDragUpdate(DragUpdateEvent event) {
  //   settings.mapPosition = settings.mapPosition! + event.delta;
  //   gameRef.gameController.queue(this, GameControl.MAP_DRAG);
  // }

  // @override
  // void onDragEnd(DragEndEvent event) {}

  // @override
  // void onDragCancel(DragCancelEvent event) {}
}
