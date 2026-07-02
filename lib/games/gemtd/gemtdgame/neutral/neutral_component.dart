import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Colors, IconData, TextPainter, TextSpan, TextStyle;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:political_think/games/gemtd/common/constants.dart';
import 'package:political_think/games/gemtd/gemtdgame/base/game_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/base/radar.dart';
import 'package:political_think/games/gemtd/gemtdgame/enemy/enemy_component.dart';

// ignore: constant_identifier_names
enum NeutralType { GATE_START, TOUCH, GATE_END, MINDER, STONE }

class NeutralComponent extends GameComponent with Radar<EnemyComponent> {
  double life = 0;
  late NeutralType neutralType;

  NeutralComponent({
    required Vector2 position,
    required Vector2 size,
    required this.neutralType,
  }) : super(
            position: position,
            size: size,
            priority: Constants.NEUTRAL_PRIORITY) {
    radarOn = false;

    if (neutralType == NeutralType.GATE_START ||
        neutralType == NeutralType.GATE_END ||
        neutralType == NeutralType.TOUCH) {
      radarOn = true;
      radarRange = (size.x + size.y) / 4;
      radarCollisionDepth = 0.9;
      radarScanAlert = (bestTarget, allTargets) {
        // Instead of calling only "onComponentReached()" on "bestTarget"
        // try to iterate over allTargets. This will help us prevent a very
        // rare issue with a freezed (not movable) enemy at "GATE_START".
        //
        // Normally "allTargets" here contains only the bestTarget item.
        // But sometimes it's possible that "allTargets" has 2 items: in this
        // case if we call "onComponentReached()" on the "bestTarget" only
        // then the second item (enemy) in allTargets most probably will freeze
        // at the "GATE_START" cell and won't move anymore, and game will be come
        // unplayable. To fix this possible issue just call
        // "onComponentReached()" on any enemy in "allTargets".
        // Mostly, the issue described above could be reproduced on slow devices.
        for (var target in allTargets) {
          if (target is EnemyComponent) {
            target.onComponentReached(this);
          }
        }
      };
    }
  }

  // Thematic markers: doom enters at the skull, snakes through the waypoints,
  // and reaches the world (Earth) at the end.
  IconData get _icon {
    switch (neutralType) {
      case NeutralType.GATE_START:
        return FontAwesomeIcons.skull.data;
      case NeutralType.GATE_END:
        return FontAwesomeIcons.earthAmericas.data;
      case NeutralType.TOUCH:
        return FontAwesomeIcons.locationDot.data;
      default:
        return FontAwesomeIcons.circle.data;
    }
  }

  Color get _color {
    switch (neutralType) {
      case NeutralType.GATE_START:
        return Colors.redAccent;
      case NeutralType.GATE_END:
        return Colors.lightBlueAccent;
      case NeutralType.TOUCH:
        return Colors.amberAccent;
      default:
        return Colors.white70;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    // Only the gates/waypoints use thematic glyphs; other neutrals (mines,
    // stones) keep whatever sprite they were given.
    if (neutralType != NeutralType.GATE_START &&
        neutralType != NeutralType.GATE_END &&
        neutralType != NeutralType.TOUCH) {
      return;
    }
    final tp = TextPainter(textDirection: TextDirection.ltr);
    tp.text = TextSpan(
      text: String.fromCharCode(_icon.codePoint),
      style: TextStyle(
        fontSize: size.x * 0.72,
        fontFamily: _icon.fontFamily,
        package: _icon.fontPackage,
        color: _color,
      ),
    );
    tp.layout();
    tp.paint(canvas, Offset((size.x - tp.width) / 2, (size.y - tp.height) / 2));
  }

  @override
  String toString() => neutralType.name;
}
