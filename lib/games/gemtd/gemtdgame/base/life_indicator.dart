import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:political_think/games/gemtd/common/constants.dart';
import 'package:political_think/games/gemtd/gemtdgame/ability/buff.dart';
import 'package:political_think/games/gemtd/gemtdgame/base/game_component.dart';

mixin LifeIndicator on GameComponent {
  double maxLife = 0;
  double life = 0;
  double prevLife = 0;

  @override
  // TODO: implement angle
  double get angle => pi / 2;

  double durationSame = 3;

  @override
  update(double dt) {
    super.update(dt);

    if (prevLife == life) {
      durationSame -= dt;
    } else {
      durationSame = 3;
    }
    prevLife = life;
  }

  late TextPainter textPainter;

  @override
  FutureOr<void>? onLoad() {
    // Need to layout here to prevent later slow load
    textPainter = TextPainter(
      text: TextSpan(
        text: (life / maxLife * 100).toStringAsFixed(0),
        style: TextConstants.gem,
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    return super.onLoad();
  }

  void renderLifIndicator(Canvas c, Set<Buff> buffs,
      [GameComponent? component]) {
    // Enemies no longer show buff icons — their active abilities are conveyed by
    // the color of their motion tail (see EnemyComponent). Gems still draw icons
    // via renderBuffs() directly.
    if (maxLife == 0) return;
    Vector2 start = Vector2.zero();
    Vector2 mid = Vector2((life / maxLife) * size.x, 0);
    Vector2 end = Vector2(size.x, 0);
    // c.drawLine(start.toOffset(), mid.toOffset(), Paint()..color = Colors.green);
    // c.drawLine(mid.toOffset(), end.toOffset(), Paint()..color = Colors.red);
    // Rect r =
    //     Rect.fromLTWH(size.x * 0.05, size.y * 0.05, size.x * 0.9, size.y * 0.9);

    if (life > 0 && life < maxLife && durationSame > 0) {
      textPainter = TextPainter(
        text: TextSpan(
          text: (life / maxLife * 100).toStringAsFixed(0),
          style: TextConstants.gem,
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      textPainter.paint(c, const Offset(0, 0));
    }
  }

  void renderBuffs(Canvas c, Set<Buff> buffs, [GameComponent? component]) {
    int i = 0;
    Set<IconData> renderIcons = {};
    for (var buff in buffs) {
      if (buff.renderType == RenderType.BOTLEFT) {
        buff.render(c, Offset(0, size.y), component);
      } else if (buff.renderType == RenderType.TOPRIGHT) {
        buff.render(c, Offset(size.x, 0), component);
      } else if (buff.renderType == RenderType.NONE) {
      } else {
        if (renderIcons.contains(buff.icon)) continue;
        renderIcons.add(buff.icon);
        var offset;
        if (i == 0) {
          offset = Offset(size.x, size.y);
        } else if (i == 1) {
          offset = Offset(size.x, size.y / 2);
        } else if (i == 2) {
          offset = Offset(size.x / 2, size.y);
        } else {
          offset = Offset(size.x / 2, size.y / 2);
        }
        buff.render(c, offset, component);
        i++;
      }
    }
  }
}
