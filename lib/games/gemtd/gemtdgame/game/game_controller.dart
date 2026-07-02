import 'dart:collection';
import 'dart:math';

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
    // Randomize the start / waypoints / end each match to keep layouts fresh.
    // All four sit on the map perimeter (interior stays open for the maze); the
    // only rule is that start must not be adjacent to end (pathing rules — a
    // valid route — are still enforced by the build system during play).
    final rand = Random();
    final maxX = (gameConst.mapGrid.x - 1).toInt();
    final maxY = (gameConst.mapGrid.y - 1).toInt();

    Vector2 randomPerimeterCell() {
      if (rand.nextBool()) {
        // Left or right edge.
        final gx = rand.nextBool() ? 0 : maxX;
        return Vector2(gx.toDouble(), rand.nextInt(maxY + 1).toDouble());
      } else {
        // Top or bottom edge.
        final gy = rand.nextBool() ? 0 : maxY;
        return Vector2(rand.nextInt(maxX + 1).toDouble(), gy.toDouble());
      }
    }

    bool adjacent(Vector2 a, Vector2 b) =>
        (a.x - b.x).abs() <= 1 && (a.y - b.y).abs() <= 1;

    var sCell = randomPerimeterCell();
    var t1Cell = randomPerimeterCell();
    var t2Cell = randomPerimeterCell();
    var eCell = randomPerimeterCell();
    for (var tries = 0; tries < 500; tries++) {
      final distinct = {
        "${sCell.x},${sCell.y}",
        "${t1Cell.x},${t1Cell.y}",
        "${t2Cell.x},${t2Cell.y}",
        "${eCell.x},${eCell.y}",
      }.length == 4;
      if (distinct && !adjacent(sCell, eCell)) break;
      sCell = randomPerimeterCell();
      t1Cell = randomPerimeterCell();
      t2Cell = randomPerimeterCell();
      eCell = randomPerimeterCell();
    }

    Vector2 toPixel(Vector2 cell) =>
        gameConst.dotMultiple(cell, gameConst.mapTileSize) +
        (gameConst.mapTileSize / 2);

    gateStart = NeutralComponent(
        position: toPixel(sCell),
        size: gameConst.mapTileSize,
        neutralType: NeutralType.GATE_START);

    touchPoint = NeutralComponent(
        position: toPixel(t1Cell),
        size: gameConst.mapTileSize,
        neutralType: NeutralType.TOUCH);

    touchPoint2 = NeutralComponent(
        position: toPixel(t2Cell),
        size: gameConst.mapTileSize,
        neutralType: NeutralType.TOUCH);

    gateEnd = NeutralComponent(
        position: toPixel(eCell),
        size: gameConst.mapTileSize,
        neutralType: NeutralType.GATE_END);

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
