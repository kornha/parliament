import 'package:flame/components.dart';
import 'package:political_think/games/gemtd/gemtdgame/base/game_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/enemy/enemy_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/bullet_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gem_component.dart';

mixin Radar<T> on GameComponent {
  bool _radarOn = false;
  // if false _best is first in scannables, else its closest raw distance
  // closest also orders _allTargets targets by distance
  // this adds an O(N) post processing step
  bool radarScanClosest = false;
  double radarRange = 0;
  double radarCollisionDepth = 0.1;
  void Function(GameComponent, Set<GameComponent>)? radarScanAlert;
  void Function()? radarScanNothing;
  void Function(Set<GemComponent>)? radarScanAllies;

  set radarOn(bool e) {
    _radarOn = e;
  }

  bool get radarOn => _radarOn;

  void radarScan(Iterable<Component> targets) {
    if (radarOn) {
      _bestDistance = 100000;

      Iterable<GameComponent> _targets = targets
          .where((e) => ((e is T) && ((e as GameComponent).active)))
          .cast();

      // We currently only allow towers to ally scan for towers
      if (this is GemComponent) {
        Iterable<GemComponent> _allies = targets
            .where((element) => element is GemComponent && collision(element))
            .cast();

        radarScanAllies?.call(_allies.toSet());
      }

      // for general scan
      _targets
          .where((value) =>
              //  we dont want to consider collisions between towers
              !(this is GemComponent && value is GemComponent) &&
              _collisionTest(value as GameComponent))
          .forEach((element) {});

      if (radarScanClosest) {
        _allTargets.toList().sort((a, b) => position
            .distanceTo(b.position)
            .compareTo(position.distanceTo(a.position)));
      }

      if (_bestTarget != null) {
        radarScanAlert?.call(_bestTarget!, _allTargets);
        _bestTarget = null;
        _allTargets = {};
      } else {
        radarScanNothing?.call();
      }
    }
  }

  double _bestDistance = 100000;
  GameComponent? _bestTarget;
  Set<GameComponent> _allTargets = {};

  bool _collisionTest(GameComponent target) {
    Vector2 targetPosition = target.position;
    double targetCollisionSize = (target.size.x + target.size.y) / 4;
    double collisionRange = (targetCollisionSize + radarRange);
    collisionRange = collisionRange * (1 - radarCollisionDepth);
    double distance = position.distanceTo(targetPosition);
    if (distance < collisionRange) {
      _allTargets.add(target);
      if (radarScanClosest) {
        if (distance < _bestDistance) {
          _bestDistance = distance;
          _bestTarget = target;
        }
        return true;
      } else {
        _bestTarget ??= target;
        return false;
      }
    }
    _allTargets.remove(target);
    return true;
  }

  bool collision(GameComponent target) {
    if (this is BulletComponent && target is BulletComponent) {
      return false;
    }
    Vector2 targetPosition = target.position;
    double targetCollisionSize = (target.size.x + target.size.y) / 4;
    double collisionRange = (targetCollisionSize + radarRange);
    collisionRange = collisionRange * (1 - radarCollisionDepth);
    double distance = position.distanceTo(targetPosition);
    if (distance < collisionRange) {
      return true;
    }
    return false;
  }
}
