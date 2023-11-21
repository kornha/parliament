import 'package:flutter/material.dart';
import 'package:political_think/common/constants.dart';
import 'package:json_annotation/json_annotation.dart';

part 'position.g.dart';

@JsonSerializable()
@immutable
class Position {
  final double value;

  const Position({
    this.value = 0.0,
  });

  factory Position.fromQuandrantDefault(Quadrant quadrant) {
    switch (quadrant) {
      case Quadrant.left:
        return const Position(value: 180.0);
      case Quadrant.center:
        return const Position(value: 90.0);
      case Quadrant.extreme:
        return const Position(value: 270.0);
      case Quadrant.right:
      default:
        return const Position(value: 0.0);
    }
  }

  Color? get color {
    switch (toQuadrant()) {
      case Quadrant.right:
        return Palette.red;
      case Quadrant.left:
        return Palette.blue;
      case Quadrant.center:
        return Palette.green;
      case Quadrant.extreme:
        return Palette.purple;
      default:
        return null;
    }
  }

  Quadrant toQuadrant() {
    var angle = value % 360;
    if (angle >= 315.0 || angle <= 45.0) {
      return Quadrant.right;
    } else if (angle > 45 && angle < 135) {
      return Quadrant.center;
    } else if (angle >= 180 && angle <= 225) {
      return Quadrant.left;
    } else {
      return Quadrant.extreme;
    }
  }

  factory Position.fromJson(Map<String, dynamic> json) =>
      _$PositionFromJson(json);

  Map<String, dynamic> toJson() => _$PositionToJson(this);
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
