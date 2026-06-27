/* 
 * canvas-astar.dart
 * MIT licensed
 *
 * Created by Daniel Imms, http://www.growingwiththeweb.com
 */

class AstarNode {
  AstarNode? parent;
  AstarNode? next;
  late int x;
  late int y;
  late double g;
  late double f;

  AstarNode(this.x, this.y, {this.parent, double cost = 0.0}) {
    g = (parent != null ? parent!.g : 0) + cost;
  }

  @override
  bool operator ==(dynamic other) {
    return (x == other.x && y == other.y);
  }

  @override
  int get hashCode => super.hashCode;
}
