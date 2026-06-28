import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:political_think/games/gemtd/gemtdgame/base/game_ref.dart';
import 'package:political_think/games/gemtd/gemtdgame/game/game_main.dart';

class GameComponent extends SpriteAnimationComponent with GameRef<GameMain> {
  GameComponent({
    Vector2? position,
    Vector2? size,
    int? priority,
  }) : super(
            position: position,
            size: size,
            priority: priority,
            anchor: Anchor.center);


  Sprite? sprite;

  bool playing = true;
  bool active = true;

  get length => (size.x + size.y) / 2;
  get radius => length / 2;
  // loadedImage(imagePath) =>
  //     Sprite.fromImage(Flame.images.loadedFiles[imagePath].loadedImage);

  @override
  void render(Canvas canvas) {
    final s = sprite;
    if (s != null) {
      // Preserve the image's aspect ratio inside the (square) tile: center it
      // and leave the surrounding space empty rather than stretching it. This
      // avoids distorting non-square city art (e.g. wide/tall skylines).
      final src = s.srcSize;
      if (src.x > 0 && src.y > 0) {
        final scale = min(size.x / src.x, size.y / src.y);
        final renderSize = Vector2(src.x * scale, src.y * scale);
        s.render(
          canvas,
          position: (size - renderSize) / 2,
          size: renderSize,
          overridePaint: paint,
        );
      } else {
        s.render(canvas, size: size, overridePaint: paint);
      }
    }
    super.render(canvas);
  }

  double angleNearTo(Vector2 target) {
    double distance = position.distanceTo(target);
    if (distance == 0) return 0;
    double radians = acos((-target.y + position.y) / distance);
    if (target.x < position.x) {
      radians = pi * 2 - radians;
    }
    return radians;
  }

  double angleProjection(
    Vector2 target,
    double projectileSpeed,
  ) {
    double distance = position.distanceTo(target);
    if (distance == 0) return 0;
    double radians = acos((-target.y + position.y) / distance);
    if (target.x < position.x) {
      radians = pi * 2 - radians;
    }
    return radians;
  }

  Vector2 positionInPrarent(Vector2 point) {
    return point + position;
  }
}
