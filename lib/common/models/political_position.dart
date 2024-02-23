import 'dart:math';

import 'package:flutter/material.dart';
import 'package:political_think/common/constants.dart';
import 'package:json_annotation/json_annotation.dart';

part 'political_position.g.dart';

@JsonSerializable()
@immutable
class PoliticalPosition {
  final double angle;

  const PoliticalPosition({
    this.angle = 90.0,
  });

  Color get color => quadrant.color;
  Color get onColor => quadrant.onColor;

  Quadrant get quadrant {
    var temp = angle % 360;
    if (temp >= 315.0 || temp <= 45.0) {
      return Quadrant.right;
    } else if (temp >= 135 && temp <= 225) {
      return Quadrant.left;
    } else if (temp > 45.0 && temp < 135.0) {
      return Quadrant.center;
    } else {
      return Quadrant.extreme;
    }
  }

  String get name {
    var temp = angle % 360;
    if (temp >= 345.0 || temp <= 15.0) {
      return "Right";
    } else if (temp > 15.0 && temp <= 45.0) {
      return "Center Right";
    } else if (temp > 45.0 && temp < 75.0) {
      return "Center Right";
    } else if (temp >= 75.0 && temp <= 105.0) {
      return "Center";
    } else if (temp > 105.0 && temp < 135.0) {
      return "Center Left";
    } else if (temp >= 135.0 && temp <= 165.0) {
      return "Center Left";
    } else if (temp > 165.0 && temp < 195.0) {
      return "Left";
    } else if (temp >= 195.0 && temp <= 225.0) {
      return "Far Left";
    } else if (temp > 225.0 && temp < 255.0) {
      return "Extreme Left";
    } else if (temp >= 255.0 && temp <= 285.0) {
      return "Extreme";
    } else if (temp > 285.0 && temp < 315.0) {
      return "Extreme Right";
    } else {
      return "Far Right";
    }
  }

  bool get isLeft => quadrant == Quadrant.left;
  bool get isRight => quadrant == Quadrant.right;
  bool get isCenter => quadrant == Quadrant.center;
  bool get isExtreme => quadrant == Quadrant.extreme;
  //double get angle => value;
  double get radians => toRadians(angle);

  static double toDegrees(double radians) {
    return radians * (180.0 / pi);
  }

  static double toRadians(double degrees) {
    return degrees * (pi / 180.0);
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
    return PoliticalPosition(angle: angle);
  }

  factory PoliticalPosition.fromQuandrant(Quadrant quadrant) {
    switch (quadrant) {
      case Quadrant.left:
        return const PoliticalPosition(angle: 180.0);
      case Quadrant.center:
        return const PoliticalPosition(angle: 90.0);
      case Quadrant.extreme:
        return const PoliticalPosition(angle: 270.0);
      case Quadrant.right:
      default:
        return const PoliticalPosition(angle: 0.0);
    }
  }

  factory PoliticalPosition.left() {
    return const PoliticalPosition(angle: 180.0);
  }

  factory PoliticalPosition.right() {
    return const PoliticalPosition(angle: 0.0);
  }

  factory PoliticalPosition.center() {
    return const PoliticalPosition(angle: 90.0);
  }

  factory PoliticalPosition.extreme() {
    return const PoliticalPosition(angle: 270.0);
  }

  factory PoliticalPosition.fromRadians(double radians) {
    return PoliticalPosition(angle: toDegrees(radians));
  }

  factory PoliticalPosition.fromJson(Map<String, dynamic> json) =>
      _$PoliticalPositionFromJson(json);

  Map<String, dynamic> toJson() => _$PoliticalPositionToJson(this);

  double distance(PoliticalPosition other) {
    var delta = (angle - other.angle).abs();
    return min(delta, 360.0 - delta);
  }

  @override
  bool operator ==(other) => other is PoliticalPosition && angle == other.angle;
  @override
  int get hashCode => angle.hashCode;
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

  Color get onColor {
    switch (this) {
      case Quadrant.right:
        return Palette.white;
      case Quadrant.left:
        return Palette.white;
      case Quadrant.center:
        return Palette.black;
      case Quadrant.extreme:
        return Palette.black;
    }
  }
}
