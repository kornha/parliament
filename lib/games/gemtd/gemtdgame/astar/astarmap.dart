/* 
 * canvas-astar.dart
 * MIT licensed
 *
 * Created by Daniel Imms, http://www.growingwiththeweb.com
 */

import 'dart:math' as math;
import 'astarnode.dart';
import 'array2d.dart';

class AstarMap {
  final double costStraight = 1.0;
  final double costDiagnal = 1.414; // approximation of sqrt(2)

  late Array2d<bool> obstacleMap;
  int width;
  int height;

  AstarMap(this.width, this.height) {
    initObstacleMap();
  }

  bool isOnMap(int x, int y) => x >= 0 && x < width && y >= 0 && y < height;

  void initObstacleMap() {
    obstacleMap = new Array2d<bool>(width, height, defaultValue: true);
  }

  void addObstacle(int x, int y) {
    obstacleMap[x][y] = false;
  }

  void removeObstacle(int x, int y) {
    obstacleMap[x][y] = true;
  }

  AstarNode? astar(AstarNode start, AstarNode goal) {
    List<AstarNode> closed = [];
    List<AstarNode> open = [start];

    open.first.f = open.first.g + heuristic(open.first, goal);

    while (open.length > 0) {
      var lowestF = 0;
      for (var i = 1; i < open.length; i++) {
        if (open[i].f < open[lowestF].f) {
          lowestF = i;
        }
      }
      AstarNode current = open[lowestF];

      if (current == goal) {
        // var info = 'Map size = ${width}x$height' +
        //     'Total number of nodes = ${width * height}' +
        //     'Number of nodes in open list = ${open.length}' +
        //     'Number of nodes in closed list = ${closed.length}';
        // print(info);
        return current;
      }

      open.removeAt(lowestF);
      closed.add(current);

      List<AstarNode> neighbors = neighborNodes(current);
      for (var i = 0; i < neighbors.length; i++) {
        if (indexOfNode(closed, neighbors[i]) == -1) {
          // Skip if in closed list
          var index = indexOfNode(open, neighbors[i]);
          if (index == -1) {
            neighbors[i].f = neighbors[i].g + heuristic(neighbors[i], goal);
            open.add(neighbors[i]);
          } else if (neighbors[i].g < open[index].g) {
            neighbors[i].f = neighbors[i].g + heuristic(neighbors[i], goal);
            open[index] = neighbors[i];
          }
        }
      }
    }

    return null;
  }

  List<AstarNode> neighborNodes(AstarNode n) {
    List<AstarNode> neighbors = <AstarNode>[];

    if (n.x > 0) {
      if (isOnMap(n.x - 1, n.y) && obstacleMap[n.x - 1][n.y])
        neighbors
            .add(new AstarNode(n.x - 1, n.y, parent: n, cost: costStraight));
      if (n.y > 0 &&
          isOnMap(n.x - 1, n.y - 1) &&
          obstacleMap[n.x - 1][n.y - 1]) {
        if (isOnMap(n.x - 1, n.y) &&
            isOnMap(n.x, n.y - 1) &&
            obstacleMap[n.x - 1][n.y] &&
            obstacleMap[n.x][n.y - 1])
          neighbors.add(
              new AstarNode(n.x - 1, n.y - 1, parent: n, cost: costDiagnal));
      }
      if (n.y < height &&
          isOnMap(n.x - 1, n.y + 1) &&
          obstacleMap[n.x - 1][n.y + 1]) {
        if (isOnMap(n.x - 1, n.y) &&
            isOnMap(n.x, n.y + 1) &&
            obstacleMap[n.x - 1][n.y] &&
            obstacleMap[n.x][n.y + 1])
          neighbors.add(
              new AstarNode(n.x - 1, n.y + 1, parent: n, cost: costDiagnal));
      }
    }
    if (n.x < width - 1) {
      if (isOnMap(n.x + 1, n.y) && obstacleMap[n.x + 1][n.y])
        neighbors
            .add(new AstarNode(n.x + 1, n.y, parent: n, cost: costStraight));
      if (n.y > 0 &&
          isOnMap(n.x + 1, n.y - 1) &&
          obstacleMap[n.x + 1][n.y - 1]) {
        if (isOnMap(n.x + 1, n.y) &&
            isOnMap(n.x, n.y - 1) &&
            obstacleMap[n.x + 1][n.y] &&
            obstacleMap[n.x][n.y - 1])
          neighbors.add(
              new AstarNode(n.x + 1, n.y - 1, parent: n, cost: costDiagnal));
      }
      if (n.y < height &&
          isOnMap(n.x + 1, n.y + 1) &&
          obstacleMap[n.x + 1][n.y + 1]) {
        if (isOnMap(n.x + 1, n.y) &&
            isOnMap(n.x, n.y + 1) &&
            obstacleMap[n.x + 1][n.y] &&
            obstacleMap[n.x][n.y + 1])
          neighbors.add(
              new AstarNode(n.x + 1, n.y + 1, parent: n, cost: costDiagnal));
      }
    }
    if (n.y > 0 && isOnMap(n.x, n.y - 1) && obstacleMap[n.x][n.y - 1])
      neighbors.add(new AstarNode(n.x, n.y - 1, parent: n, cost: costStraight));
    if (n.y < height - 1 && isOnMap(n.x, n.y + 1) && obstacleMap[n.x][n.y + 1])
      neighbors.add(new AstarNode(n.x, n.y + 1, parent: n, cost: costStraight));

    return neighbors;
  }

  int indexOfNode(List<AstarNode> array, AstarNode node) {
    for (var i = 0; i < array.length; i++) {
      if (node == array[i]) return i;
    }
    return -1;
  }

  num heuristic(node, goal) {
    return diagonalDistance(node, goal);
  }

  num manhattanDistance(node, goal) {
    return (node.x - goal.x).abs() + (node.y - goal.y).abs();
  }

  num diagonalUniformDistance(node, goal) {
    return math.max((node.x - goal.x).abs(), (node.y - goal.y).abs());
  }

  num diagonalDistance(AstarNode node, AstarNode goal) {
    var dmin = math.min((node.x - goal.x).abs(), (node.y - goal.y).abs());
    var dmax = math.max((node.x - goal.x).abs(), (node.y - goal.y).abs());
    return costDiagnal * dmin + costStraight * (dmax - dmin);
  }

  num euclideanDistance(node, goal) {
    return math.sqrt((node.x - goal.x).abs() ^ 2 + (node.y - goal.y).abs() ^ 2);
  }
}
