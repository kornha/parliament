import 'dart:math';

import 'package:flame/effects.dart';

class SmartRotateEffect extends RotateEffect {
  void Function()? onComplete;
  SmartRotateEffect.to(double angle, EffectController controller)
      : _destinationAngle = angle,
        super.by(0, controller);

  double _angle = 0;
  double _destinationAngle;

  @override
  void onStart() {
    _angle = _destinationAngle - target.angle;
    if (_angle > pi) {
      _angle = _angle - (pi * 2);
    }
    if (_angle < -pi) {
      _angle = _angle + (pi * 2);
    }
  }

  @override
  void onFinish() {
    if (target.angle < 0) {
      target.angle += (pi * 2);
    }
    if (target.angle > (pi * 2)) {
      target.angle -= (pi * 2);
    }
    onComplete?.call();
  }

  @override
  void apply(double progress) {
    final dProgress = progress - previousProgress;
    target.angle += _angle * dProgress;
    super.apply(progress);
  }
}
