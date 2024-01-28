import 'dart:math';
import 'dart:ui';

import 'joystick.dart';

abstract class StickOffsetCalculator {
  Offset calculate({
    required JoystickMode mode,
    required Offset startDragStickPosition,
    required Offset currentDragStickPosition,
    required Size baseSize,
  });
}

class CircleStickOffsetCalculator implements StickOffsetCalculator {
  const CircleStickOffsetCalculator();

  @override
  Offset calculate({
    required JoystickMode mode,
    required Offset startDragStickPosition,
    required Offset currentDragStickPosition,
    required Size baseSize,
  }) {
    double x = currentDragStickPosition.dx - startDragStickPosition.dx;
    double y = currentDragStickPosition.dy - startDragStickPosition.dy;
    final radius = baseSize.width / 2;

    final isPointInCircle = x * x + y * y < radius * radius;

    if (!isPointInCircle) {
      final mult = sqrt(radius * radius / (y * y + x * x));
      x *= mult;
      y *= mult;
    }

    final xOffset = x / radius;
    final yOffset = y / radius;

    switch (mode) {
      case JoystickMode.all:
        return Offset(xOffset, yOffset);
      case JoystickMode.vertical:
        return Offset(0.0, yOffset);
      case JoystickMode.horizontal:
        return Offset(xOffset, 0.0);
      case JoystickMode.horizontalAndVertical:
        return Offset(xOffset.abs() > yOffset.abs() ? xOffset : 0,
            yOffset.abs() > xOffset.abs() ? yOffset : 0);
    }
  }
}

class RectangleStickOffsetCalculator implements StickOffsetCalculator {
  const RectangleStickOffsetCalculator();

  @override
  Offset calculate({
    required JoystickMode mode,
    required Offset startDragStickPosition,
    required Offset currentDragStickPosition,
    required Size baseSize,
  }) {
    double x = currentDragStickPosition.dx - startDragStickPosition.dx;
    double y = currentDragStickPosition.dy - startDragStickPosition.dy;

    final xOffset = _normalizeOffset(x / (baseSize.width / 2));
    final yOffset = _normalizeOffset(y / (baseSize.height / 2));

    switch (mode) {
      case JoystickMode.all:
        return Offset(xOffset, yOffset);
      case JoystickMode.vertical:
        return Offset(0.0, yOffset);
      case JoystickMode.horizontal:
        return Offset(xOffset, 0.0);
      case JoystickMode.horizontalAndVertical:
        return Offset(xOffset.abs() > yOffset.abs() ? xOffset : 0,
            yOffset.abs() > xOffset.abs() ? yOffset : 0);
    }
  }

  double _normalizeOffset(double point) {
    if (point > 1) {
      return 1;
    }
    if (point < -1) {
      return -1;
    }
    return point;
  }
}
