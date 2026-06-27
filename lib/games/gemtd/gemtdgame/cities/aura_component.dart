import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:political_think/games/gemtd/gemtdgame/ability/buff.dart';
import 'package:political_think/games/gemtd/gemtdgame/base/game_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/base/radar.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gem_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/enemy/enemy_component.dart';

import '../../common/constants.dart';

class AuraComponent extends GameComponent with Radar<EnemyComponent> {
  double damage = 0;
  Set<Buff> buffs = {};

  final SpriteSheet spriteSheet;
  final double projectileStepTime;
  final double scanSize;
  final double projectileScale;
  final GemComponent source;

  AuraComponent({
    required Vector2 position,
    required this.scanSize,
    required this.spriteSheet,
    required this.projectileStepTime,
    required this.projectileScale,
    required this.source,
  }) : super(
            position: position,
            size: Vector2(0, 0),
            priority: Constants.AURA_PRIORITY);

  @override
  FutureOr<void> onLoad() {
    size = Vector2(0, 0);
    radarOn = true;
    radarScanAlert = onHitEnemy;
    radarScanNothing = null;
    radarCollisionDepth = 0.2;
    radarRange = scanSize;

    // * 2 since scanSize is the radius
    // need to scale in case projectile doesnt fill square
    double currentSize = scanSize * 2 * projectileScale;
    size = Vector2(currentSize, currentSize);

    setAnimation();

    return super.onLoad();
  }

  void setAnimation() {
    List<Sprite> sprites = [];

    for (int i = 0; i < spriteSheet.rows; i++) {
      for (int j = 0; j < spriteSheet.columns; j++) {
        sprites.add(spriteSheet.getSprite(
            spriteSheet.rows - 1 - i, spriteSheet.columns - 1 - j));
      }
    }

    animation = SpriteAnimation.spriteList(sprites,
        stepTime: projectileStepTime, loop: false);

    animationTicker?.onComplete = removeFromParent;
  }

  Set<GameComponent> hit = {};
  void onHitEnemy(GameComponent enemy, Set<GameComponent> targets) {
    targets.forEach((target) {
      if (!hit.contains(target)) {
        (target as EnemyComponent).receiveDamage(damage, buffs, source);
        hit.add(target);
      }
    });
  }
}
