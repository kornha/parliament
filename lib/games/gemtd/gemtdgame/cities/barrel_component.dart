import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:political_think/games/gemtd/common/constants.dart';
import 'package:political_think/games/gemtd/gemtdgame/base/game_component.dart';
import 'package:political_think/games/gemtd/gemtdgame/base/smart_rotate_effect.dart';

class BarrelComponent extends GameComponent {
  BarrelComponent({required Vector2 position, required Vector2 size})
      : super(
            position: position,
            size: size,
            priority: Constants.CITY_PRIORITY + 1);
  double rotateSpeed = 6.0; /* radians/second */
  double rotateTo(double radians, void Function()? onComplete) {
    double duration = (radians - angle).abs() / rotateSpeed;
    if (duration <= 0) {
      onComplete?.call();
      return 0;
    }
    add(
      SmartRotateEffect.to(
        radians,
        EffectController(
          duration: duration,
          curve: Curves.easeOut,
          infinite: false,
        ),
      )..onComplete = onComplete,
    );

    return duration;
  }
}
