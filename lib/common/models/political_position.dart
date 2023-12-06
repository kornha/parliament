import 'dart:math';

import 'package:flutter/material.dart';
import 'package:political_think/common/constants.dart';
import 'package:json_annotation/json_annotation.dart';

part 'political_position.g.dart';

@JsonSerializable()
@immutable
class PoliticalPosition {
  final double value;

  const PoliticalPosition({
    this.value = 0.0,
  });

  Color get color {
    switch (quadrant) {
      case Quadrant.right:
        return Palette.red;
      case Quadrant.left:
        return Palette.blue;
      case Quadrant.center:
        return Palette.green;
      case Quadrant.extreme:
        return Palette.purple;
    }
  }

  Quadrant get quadrant {
    var angle = value % 360;
    if (angle >= 315.0 || angle <= 45.0) {
      return Quadrant.right;
    } else if (angle >= 135 && angle <= 225) {
      return Quadrant.left;
    } else if (angle > 45.0 && angle < 135.0) {
      return Quadrant.center;
    } else {
      return Quadrant.extreme;
    }
  }

  static double toDegrees(double radians) {
    return radians * (180.0 / pi);
  }

  static double toRadians(double degrees) {
    return degrees * (pi / 180.0);
  }

  factory PoliticalPosition.fromQuandrant(Quadrant quadrant) {
    switch (quadrant) {
      case Quadrant.left:
        return const PoliticalPosition(value: 180.0);
      case Quadrant.center:
        return const PoliticalPosition(value: 90.0);
      case Quadrant.extreme:
        return const PoliticalPosition(value: 270.0);
      case Quadrant.right:
      default:
        return const PoliticalPosition(value: 0.0);
    }
  }

  // finds the angle against the X axis, up to 360 degrees
  // kind of hacky but it should work
  // .abs() is used because I saw -0.00
  static PoliticalPosition? fromCoordinate(double x, double y) {
    if (x == 0 && y == 0) return null;
    var angle = toDegrees(-atan2(y, x));
    if (angle < 0) {
      angle += 360.0;
    }
    angle = angle.abs();
    return PoliticalPosition(value: angle);
  }

  factory PoliticalPosition.fromJson(Map<String, dynamic> json) =>
      _$PoliticalPositionFromJson(json);

  Map<String, dynamic> toJson() => _$PoliticalPositionToJson(this);

  double distance(PoliticalPosition other) {
    var delta = (value - other.value).abs();
    return min(delta, 360.0 - delta);
  }
}

enum Quadrant {
  right,
  left,
  center,
  extreme;

  static Quadrant? fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'right':
        return Quadrant.right;
      case 'left':
        return Quadrant.left;
      case 'center':
        return Quadrant.center;
      case 'extreme':
        return Quadrant.extreme;
      default:
        return null;
    }
  }

  Color get color {
    switch (this) {
      case Quadrant.right:
        return Palette.red;
      case Quadrant.left:
        return Palette.blue;
      case Quadrant.center:
        return Palette.green;
      case Quadrant.extreme:
        return Palette.purple;
    }
  }
}
