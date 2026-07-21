import 'dart:async';
import 'dart:math';

import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:political_think/games/gemtd/common/constants.dart';
import 'package:political_think/games/gemtd/gemtdgame/ability/buff.dart';
import 'package:political_think/games/gemtd/gemtdgame/base/fx.dart';
import 'package:political_think/games/gemtd/gemtdgame/base/game_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/base/movable.dart';
import 'package:political_think/games/gemtd/gemtdgame/base/radar.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gem_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/enemy/enemy_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/view/game_stats.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/weapon_settings.dart';

class BulletComponent extends GameComponent
    with Movable, Radar<EnemyComponent> {
  // double range = 0;
  // Function? onExplosion;
  double damage = 0;
  Set<Buff> buffs = {};

  bool canHitIntermediateTargets = true;

  final GemAttributes settings;
  //TODO: pass in settings component
  SpriteSheet spriteSheet;
  bool loop;
  double projectileStepTime;
  GemComponent source;

  // Explosion
  late SpriteSheet explosion;
  late List<Sprite> explosionSprites;

  EnemyComponent enemy;

  BulletComponent({
    required Vector2 position,
    required Vector2 size,
    required this.enemy,
    required this.spriteSheet,
    required this.source,
    required this.settings,
    this.loop = true,
    this.projectileStepTime = 0.1,
  }) : super(
            position: position,
            size: size,
            priority: Constants.PROJECTILE_PRIORITY) {
    double rad = angleNearTo(enemy.position);
    angle = rad;
  }

  @override
  Future<void>? onLoad() async {
    explosion = SpriteSheet.fromColumnsAndRows(
      image: await Images().load(settings.explosionImage),
      columns: settings.explosionColumns,
      rows: settings.explosionRows,
    );
    createExpolosionAnimation();
    // radar
    setRadar();
    onMoveFinish = this.outOfRange;
    if (settings.homingProjectiles) {
      moveToMovable(enemy);
      enemy.onKilledCallback = onEnemyKilled;
    } else {
      // Lane shot: a straight line through the target's current position out
      // to the tower's full range. No tracking, and no tie to the seed
      // target's life — the charge belongs to the lane, not the enemy.
      var dir = enemy.position - position;
      if (dir.length2 == 0) {
        final rad = angleNearTo(enemy.position);
        dir = Vector2(sin(rad), -cos(rad));
      }
      dir.normalize();
      moveTo(position + dir * (source.radarRange * 1.2));
    }

    setAnimation();

    return super.onLoad();
  }

  void setRadar() {
    radarOn = true;
    radarScanClosest = false;
    radarRange = (size.x + size.y) / 4;
    radarScanAlert = onRadarScan;
    radarScanNothing = null;
    radarCollisionDepth = 0.2;
  }

  @override
  void update(double dt) {
    if (active) {
      updateMovable(dt);
    }
    super.update(dt);
  }

  @override
  void render(Canvas canvas) {
    // Glowing projectile core, drawn behind the bullet sprite.
    Fx.glow(canvas, size, source.color);
    super.render(canvas);
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
        stepTime: projectileStepTime, loop: loop);
  }

  void onRadarScan(GameComponent enemy, Set<GameComponent> targets) {
    if (!canHitIntermediateTargets) {
      if (enemy != this.enemy) return;
    }
    radarOn = false;
    parent?.add(
      ExplosionComponent(
          position: enemy.position, size: settings.explosionSize, bullet: this)
        ..animation = SpriteAnimation.spriteList(
          explosionSprites,
          stepTime: settings.explosionStepTime,
          loop: false,
        ),
    );
    // Procedural flash + sparks layered over the sprite explosion.
    final p = parent;
    if (p != null) {
      Fx.explosion(
          p, enemy.position.clone(), source.color, settings.explosionSize.x);
    }
    bool finish = buffs
        .every((buff) => buff.bulletDidHitEnemy(this, enemy as EnemyComponent));
    (enemy as EnemyComponent).receiveDamage(damage, buffs, source);

    if (finish) {
      moveFinish();
    } else {
      radarOn = true;
    }
  }

  void outOfRange() {
    radarOn = false;
    moveFinish();
  }

  void onEnemyKilled() {
    radarOn = false;
    moveFinish();
  }

  void createExpolosionAnimation() {
    // List<Vector2> expFrame = [];
    // List<dynamic> vector2List = settings.expParams;
    // for (int i = 0; i < vector2List.length; i++) {
    //   List<dynamic> vector2 = vector2List[i];
    //   expFrame.add(Vector2(vector2[0], vector2[1]));
    // }
    List<Sprite> sprites = [];
    // expFrame.forEach(
    //     (v) => sprites.add(explosion.getSprite(v.x.toInt(), v.y.toInt())));
    for (int i = 0; i < settings.explosionRows; i++) {
      for (int j = 0; j < settings.explosionColumns; j++) {
        sprites.add(explosion.getSprite(i, j));
      }
    }
    explosionSprites = sprites;
  }
}

class ExplosionComponent extends GameComponent with Radar<EnemyComponent> {
  ExplosionComponent({
    required Vector2 position,
    required Vector2 size,
    required this.bullet,
  }) : super(
            position: position,
            size: size,
            priority: Constants.PROJECTILE_PRIORITY);

  final BulletComponent bullet;

  @override
  set animation(SpriteAnimation? a) {
    super.animation = a;
    animationTicker?.onComplete = removeFromParent;
  }

  @override
  FutureOr<void> onLoad() {
    radarOn = bullet.settings.aoe;
    radarRange = (size.x + size.y) / 4;
    radarScanAlert = onHitEnemy;
    radarScanNothing = null;
    radarCollisionDepth = 0.2;

    return super.onLoad();
  }

  // radar on bug?
  void onHitEnemy(GameComponent enemy, Set<GameComponent> targets) {
    radarOn = false;
    targets.forEach((e2) {
      // TODO:
      // We assume the enemy damage is done in bullet
      // probably can refactor
      if (enemy != e2) {
        (e2 as EnemyComponent)
            .receiveDamage(bullet.damage, bullet.buffs, bullet.source);
      }
    });
  }
}
