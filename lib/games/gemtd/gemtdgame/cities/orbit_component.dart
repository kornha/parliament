import 'dart:math';

import 'package:flame/components.dart';
import 'package:political_think/games/gemtd/common/constants.dart';
import 'package:political_think/games/gemtd/gemtdgame/base/game_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/base/radar.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gem_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/enemy/enemy_component.dart';

// A "bird" that orbits a tower and damages enemies it passes through (Vultures).
// Uses the same Radar-based detection as ExplosionComponent; position is updated
// each frame to trace a circle around the owning gem.
class OrbitComponent extends GameComponent with Radar<EnemyComponent> {
  OrbitComponent({
    required this.gem,
    required this.orbitRadius,
    required this.angularSpeed,
    required double startAngle,
    required Vector2 size,
    this.spritePath = "weapon/chevron.png",
  })  : _angle = startAngle,
        super(
            position: Vector2.zero(),
            size: size,
            priority: Constants.PROJECTILE_PRIORITY);

  final GemComponent gem;
  final double orbitRadius;
  final double angularSpeed;
  final String spritePath;
  double _angle;

  // Per-enemy cooldown so a bird doesn't tick damage every frame on one enemy.
  final Map<EnemyComponent, double> _cooldown = {};
  static const double _cooldownTime = 0.5;

  @override
  Future<void>? onLoad() async {
    sprite = await Sprite.load(spritePath);
    radarOn = true;
    radarScanClosest = false;
    radarRange = (size.x + size.y) / 4;
    radarScanAlert = _onHit;
    radarScanNothing = null;
    radarCollisionDepth = 0.2;
    _updatePosition();
    return super.onLoad();
  }

  void _updatePosition() {
    final center = gem.absoluteCenter;
    position = center + Vector2(cos(_angle), sin(_angle)) * orbitRadius;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (gem.isRemoved || !gem.isMounted) {
      removeFromParent();
      return;
    }
    _angle += angularSpeed * dt;
    _updatePosition();
    for (final k in _cooldown.keys.toList()) {
      final v = _cooldown[k]! - dt;
      if (v <= 0) {
        _cooldown.remove(k);
      } else {
        _cooldown[k] = v;
      }
    }
  }

  void _onHit(GameComponent enemy, Set<GameComponent> targets) {
    for (final t in targets) {
      if (t is EnemyComponent && !_cooldown.containsKey(t)) {
        t.receiveDamage(gem.currentDamage, {}, gem);
        _cooldown[t] = _cooldownTime;
      }
    }
  }
}
