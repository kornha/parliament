import 'dart:math';
import 'dart:ui';

import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:political_think/games/gemtd/common/constants.dart';
import 'package:political_think/games/gemtd/gemtdgame/ability/status_manager.dart';
import 'package:political_think/games/gemtd/gemtdgame/astar/astarnode.dart';
import 'package:political_think/games/gemtd/gemtdgame/base/fx.dart';
import 'package:political_think/games/gemtd/gemtdgame/base/game_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/base/life_indicator.dart';
import 'package:political_think/games/gemtd/gemtdgame/base/movable.dart';
import 'package:political_think/games/gemtd/gemtdgame/base/scanable.dart';
import 'package:political_think/games/gemtd/gemtdgame/cities/gem_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/enemy/enemy_setting.dart';
import 'package:political_think/games/gemtd/gemtdgame/game/game_controller.dart';
import 'package:political_think/games/gemtd/gemtdgame/neutral/neutral_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/view/weapon_factory_view.dart';

import '../ability/buff.dart';

class EnemyComponent extends GameComponent
    with TapCallbacks, Scanable, Movable, EnemyPath, LifeIndicator {
  double armor = 0;
  double receiveDamageMultiplier = 1.0;
  double capital = 1.0;
  bool dead = false;
  int level = 1;
  GemComponent? lastDamageProc;

  // White flash on taking a real hit (0..1, fades out in update()).
  double _hitFlash = 0;

  // @override
  // bool get updateAngle => false;

  Function? onKilledCallback;

  @override
  bool onTapDown(TapDownEvent event) {
    gameRef.gameController.queue(this, GameControl.ENEMY_SHOW_ACTION);
    return false;
  }

  late SpriteSheet spriteSheet;
  SpriteSheet? _originalSpriteSheet;
  bool _isHexed = false;
  bool _wasStarred = false;

  //this only performs shallow copy so be careful!
  late List<NeutralComponent> objectives =
      List.from(gameRef.enemyFactory.objectives);

  EnemyComponent({
    required Vector2 position,
    required Vector2 size,
  }) : super(position: position, priority: Constants.ENEMY_PRIORITY);

  Set<Buff> buffs = {};

  // Recent world positions, used to draw the colored motion tail.
  final List<Vector2> _trail = [];

  EnemySettings settings = EnemySettings();

  final images = Images();

  @override
  Future<void>? onLoad() async {
    life = settings.baseLife(level);
    maxLife = life;
    speed = settings.baseSpeed(level);
    size = gameSetting.enemySize * settings.scale;
    armor = settings.baseArmor(level);
    receiveDamageMultiplier = settings.baseReceiveDamageMultiplier(level);
    spriteSheet = SpriteSheet.fromColumnsAndRows(
      image: await images.load(settings.spritePath),
      columns: settings.spriteColumns,
      rows: settings.spriteRows,
    );
    setLiveAnimation();

    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);

    StatusManager.tickEnemy(dt, this, buffs);

    // Fade the hit-flash and tint the sprite toward white while it's active.
    if (_hitFlash > 0) {
      _hitFlash = (_hitFlash - dt / 0.12).clamp(0.0, 1.0);
      paint.colorFilter = _hitFlash > 0
          ? ColorFilter.mode(
              Colors.white.withOpacity((_hitFlash * 0.7).clamp(0.0, 1.0)),
              BlendMode.srcATop,
            )
          : null;
    }

    final hasHex = buffs.any((b) => b is Hex);
    if (hasHex && !_isHexed) {
      _originalSpriteSheet = spriteSheet;
      _loadHexSprite();
      _isHexed = true;
    } else if (!hasHex && _isHexed) {
      spriteSheet = _originalSpriteSheet!;
      setLiveAnimation();
      _isHexed = false;
    }

    // Hollywood's "Star": invulnerable while it shines, then the fall is fatal.
    final hasStar = buffs.any((b) => b is Star);
    if (hasStar) {
      _wasStarred = true;
    } else if (_wasStarred) {
      _wasStarred = false;
      life = 0;
    }

    if (life <= 0) {
      if (!dead) onKilled();
      dead = true;
      active = false;
    }

    if (active) {
      updateMovable(dt);
    }

    // Record a short position history for the motion tail.
    _trail.add(position.clone());
    if (_trail.length > 10) _trail.removeAt(0);
  }

  @override
  void render(Canvas c) {
    _renderTail(c);
    super.render(c);
    renderLifIndicator(c, buffs, this);
  }

  // The tail's color reflects the enemy's active abilities (combined) — debuffs
  // read as color instead of icons. No abilities => the enemy's own theme color.
  Color _tailColor() {
    if (buffs.isEmpty) return settings.gemType.color();
    double r = 0, g = 0, b = 0;
    for (final buff in buffs) {
      final col = buff.color;
      r += col.red;
      g += col.green;
      b += col.blue;
    }
    final n = buffs.length;
    return Color.fromARGB(
        255, (r / n).round(), (g / n).round(), (b / n).round());
  }

  // A motion-blur tail: fading colored blobs along the enemy's recent path.
  void _renderTail(Canvas c) {
    if (_trail.length < 2) return;
    final col = _tailColor();
    final len = _trail.length;
    for (int j = 0; j < len; j++) {
      final local = (_trail[j] - position) + size / 2;
      final t = j / (len - 1); // 0 = oldest, 1 = newest
      final radius = size.x * (0.12 + 0.28 * t);
      final alpha = (0.38 * t).clamp(0.0, 1.0);
      c.drawCircle(
          local.toOffset(), radius, Paint()..color = col.withOpacity(alpha));
    }
  }

  @override
  void onRemove() {
    pathNode = null;
    super.onRemove();
  }

  double initAngle = pi / 2;

  set angle(double a) {
    super.angle = a - initAngle;
  }

  void receiveDamage(double damage, Set<Buff> buffs, GemComponent attacker) {
    // In case damage is done before killed can be triggered
    if (life <= 0) return;
    // A "Star" (Hollywood) is invulnerable and immune to new debuffs while it
    // shines; it dies when the star fades (see update()). The starring hit
    // itself still lands, because the Star buff isn't on the enemy yet.
    if (this.buffs.any((b) => b is Star)) return;
    // check if not empty stops infinite loop from status_manager
    if (buffs.isNotEmpty) {
      this.buffs.forEach((buff) {
        if (buffs.contains(buff)) {
          buff.resetDuration();
          //
          if (buff.stacks != null &&
              (buff.maxStacks == null || buff.stacks! < buff.maxStacks!)) {
            buff.stacks = buff.stacks! + 1;
          }
        }
      });

      this.buffs.addAll(buffs);
      StatusManager.computeEnemyStatus(null, buffs, this);
    }
    var damageAfterReceiveDamageMultiplier = damage * receiveDamageMultiplier;
    var damageAfterArmor = damageAfterReceiveDamageMultiplier *
        (maxLife / (maxLife + armor * 0.05 * maxLife));
    if (damageAfterArmor > 0) {
      lastDamageProc = attacker;
      // Flash only on a meaningful hit, so per-frame DoT ticks don't keep it lit.
      if (damageAfterArmor > maxLife * 0.012) _hitFlash = 1.0;
      final lifeAfterDamage = life - damageAfterArmor;
      if (lifeAfterDamage > maxLife) {
        // A very rare case (reproduced just few times during my game experience).
        // If a life of the enemy after its damaging becomes > maxLife, then
        // just use maxLife instead.
        // (Agreed with Alex: it should be possible to "heal" the enemy eg.,
        // you can do "negative" damage, don't let the math set it > 100%)
        life = maxLife;
      } else {
        life = lifeAfterDamage;
      }
    }
  }

  void onComponentReached(NeutralComponent component) {
    objectives.remove(component);
    moveNext();
  }

  void onComplete() {
    if (!dead) {
      active = false;
      gameRef.gameController.queue(this, GameControl.ENEMY_MISSED);
      this.removeFromParent();
    }
  }

  void onKilled() {
    // Burst of sparks in the enemy's color as it dies.
    final p = parent;
    if (p != null) {
      Fx.explosion(p, position.clone(), settings.gemType.color(), size.x * 0.7,
          sparks: 10);
    }
    setDeadAnimation();
    onKilledCallback?.call();
    active = false;
    gameRef.gameController
        .queue(this, GameControl.ENEMY_KILLED, lastDamageProc);
    this.removeFromParent();
  }

  void setLiveAnimation() {
    List<Sprite> sprites = [];
    sprites.add(spriteSheet.getSprite(0, 0));
    sprites.add(spriteSheet.getSprite(0, 1));
    sprites.add(spriteSheet.getSprite(0, 2));
    sprites.add(spriteSheet.getSprite(0, 3));
    sprites.add(spriteSheet.getSprite(0, 4));
    sprites.add(spriteSheet.getSprite(0, 5));
    sprites.add(spriteSheet.getSprite(0, 6));
    sprites.add(spriteSheet.getSprite(0, 7));
    sprites.add(spriteSheet.getSprite(0, 8));
    sprites.add(spriteSheet.getSprite(0, 9));
    sprites.add(spriteSheet.getSprite(0, 10));
    sprites.add(spriteSheet.getSprite(0, 11));

    sprites.add(spriteSheet.getSprite(1, 0));
    sprites.add(spriteSheet.getSprite(1, 1));
    sprites.add(spriteSheet.getSprite(1, 2));
    sprites.add(spriteSheet.getSprite(1, 3));
    sprites.add(spriteSheet.getSprite(1, 4));
    sprites.add(spriteSheet.getSprite(1, 5));
    sprites.add(spriteSheet.getSprite(1, 6));
    sprites.add(spriteSheet.getSprite(1, 7));
    sprites.add(spriteSheet.getSprite(1, 8));
    sprites.add(spriteSheet.getSprite(1, 9));
    sprites.add(spriteSheet.getSprite(1, 10));
    sprites.add(spriteSheet.getSprite(1, 11));

    sprites.add(spriteSheet.getSprite(2, 0));
    sprites.add(spriteSheet.getSprite(2, 1));
    sprites.add(spriteSheet.getSprite(2, 2));
    sprites.add(spriteSheet.getSprite(2, 3));
    sprites.add(spriteSheet.getSprite(2, 4));
    sprites.add(spriteSheet.getSprite(2, 5));
    sprites.add(spriteSheet.getSprite(2, 6));
    sprites.add(spriteSheet.getSprite(2, 7));
    sprites.add(spriteSheet.getSprite(2, 8));
    sprites.add(spriteSheet.getSprite(2, 9));
    sprites.add(spriteSheet.getSprite(2, 10));
    sprites.add(spriteSheet.getSprite(2, 11));

    sprites.add(spriteSheet.getSprite(3, 0));
    sprites.add(spriteSheet.getSprite(3, 1));
    sprites.add(spriteSheet.getSprite(3, 2));
    sprites.add(spriteSheet.getSprite(3, 3));
    sprites.add(spriteSheet.getSprite(3, 4));
    sprites.add(spriteSheet.getSprite(3, 5));
    sprites.add(spriteSheet.getSprite(3, 6));
    sprites.add(spriteSheet.getSprite(3, 7));
    sprites.add(spriteSheet.getSprite(3, 8));
    sprites.add(spriteSheet.getSprite(3, 9));
    sprites.add(spriteSheet.getSprite(3, 10));
    sprites.add(spriteSheet.getSprite(3, 11));

    animation = SpriteAnimation.spriteList(sprites, stepTime: 0.02, loop: true);
  }

  void _loadHexSprite() async {
    spriteSheet = SpriteSheet.fromColumnsAndRows(
      image: await images.load('enemy/critter.png'),
      columns: settings.spriteColumns,
      rows: settings.spriteRows,
    );
    setLiveAnimation();
  }

  void setDeadAnimation() {
    List<Sprite> sprites = [];
    sprites.add(spriteSheet.getSprite(0, 0));
    sprites.add(spriteSheet.getSprite(1, 0));
    sprites.add(spriteSheet.getSprite(2, 0));
    animation = SpriteAnimation.spriteList(sprites, stepTime: 0.1, loop: false);
  }
}

mixin EnemyPath on GameComponent {
  /*Enemy move path controller */
  AstarNode? pathNode;

  void moveSmart(Vector2 to) {
    pathNode = gameRef.mapController.astarMapResolve(position, to);
    if (pathNode != null) {
      pathNextMove();
    }
  }

  void moveNext() {
    if ((this as EnemyComponent).objectives.isEmpty) {
      (this as EnemyComponent).onComplete();
    } else {
      var objective = (this as EnemyComponent).objectives[0];
      pathNode =
          gameRef.mapController.astarMapResolve(position, objective.position);
      if (pathNode != null) {
        pathNextMove();
      }
    }
  }

  void pathNextMove() {
    if (pathNode != null) {
      if (pathNode!.next != null) {
        pathNode = pathNode!.next;
      }
      // print(pathNode!.x.toString() + "," + pathNode!.y.toString());
      (this as Movable).moveTo(moveNextPosition(pathNode!), true, pathNextMove);
    }
  }

  Vector2 moveNextPosition(AstarNode node) {
    Vector2 lefttop = gameRef.mapController.nodeToPosition(node);
    return lefttop + (gameRef.mapController.tileSize / 2);
  }
}

class HospitalityEnemyComponent extends EnemyComponent {
  HospitalityEnemyComponent({required super.position, required super.size});
  @override
  EnemySettings get settings => HospitalitySettings();
}

class SAmericaEnemyComponent extends EnemyComponent {
  SAmericaEnemyComponent({required super.position, required super.size});
  @override
  EnemySettings get settings => SAmericaEnemySettings();
}

class SAsiaEnemyComponent extends EnemyComponent {
  SAsiaEnemyComponent({required super.position, required super.size});
  @override
  EnemySettings get settings => SAsiaSettings();
}

class EntertainmentEnemyComponent extends EnemyComponent {
  EntertainmentEnemyComponent({required super.position, required super.size});
  @override
  EnemySettings get settings => EntertainmentSettings();
}

class TechEnemyComponent extends EnemyComponent {
  TechEnemyComponent({required super.position, required super.size});
  @override
  EnemySettings get settings => TechSettings();
}

class MenaEnemyComponent extends EnemyComponent {
  MenaEnemyComponent({required super.position, required super.size});
  @override
  EnemySettings get settings => MenaEnemySettings();
}

class FinanceEnemyComponent extends EnemyComponent {
  FinanceEnemyComponent({required super.position, required super.size});
  @override
  EnemySettings get settings => FinanceSettings();
}

class EEuropeEnemyComponent extends EnemyComponent {
  EEuropeEnemyComponent({required super.position, required super.size});
  @override
  EnemySettings get settings => EEuropeEnemySettings();
}
