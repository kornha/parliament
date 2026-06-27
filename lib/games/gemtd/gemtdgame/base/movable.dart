import 'package:flame/components.dart';
import 'package:political_think/games/gemtd/gemtdgame/base/game_component.dart';
import 'dart:math';

import 'package:political_think/games/gemtd/gemtdgame/enemy/enemy_component.dart';

mixin Movable on GameComponent {
  double speed = 0;
  Function? onMoveFinish;
  bool _finish = true;

  Vector2 _direction = Vector2.zero();
  double _totalLength = 0;
  double _movedLength = 0;
  Movable? other;
  bool updateAngle = true;

  void moveTo(Vector2 to, [bool reset = true, Function? onFinish]) {
    moveFromTo(position, to, reset, onFinish);
  }

  void moveToMovable(Movable other) {
    this.other = other;
    moveTo(other.position);
  }

  void moveFromTo(Vector2 from, Vector2 to,
      [bool reset = true, Function? onFinish]) {
    // Vector2 = from;
    double dx = to.x - from.x;
    double dy = to.y - from.y;
    double dl = sqrt(pow(dx, 2) + pow(dy, 2));
    _direction = Vector2(dx / dl, dy / dl);

    //use this if we wish to impose bullet travel limit
    if (reset) {
      _totalLength = dl;
      _movedLength = 0;
      _finish = false;
      onMoveFinish = onFinish;
    }
    if (updateAngle) angle = angleNearTo(to);
  }

  void updateMovable(double t) {
    // super.update(t);
    if (!_finish) {
      /*finish on the next tick,  to make sure the Vector2 is able to be sensored*/
      if (_movedLength > _totalLength) {
        moveFinish();
      }

      if (other != null) {
        moveTo(other!.position);
        if (other!.isRemoved) {
          // in case finish was not set for some reason..
          this.removeFromParent();
        }
      }

      double _delta = t * speed * 100;
      double dx = _delta * _direction.x;
      double dy = _delta * _direction.y;
      //overwirte Vector2 to make sure it update area.
      position = position + Vector2(dx, dy);
      //OPT: check only after time expire, to avoid pow cacl in very tick
      _movedLength += sqrt(pow(dx, 2) + pow(dy, 2));
    } else {
      this.removeFromParent();
    }
  }

  void moveFinish() {
    _finish = true;
    onMoveFinish?.call();
  }
}
