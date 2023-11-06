import 'package:flutter/material.dart';
import 'package:political_think/common/constants.dart';
import 'package:json_annotation/json_annotation.dart';

part 'position.g.dart';

@JsonSerializable()
@immutable
class Position {
  final double value;

  Position({
    this.value = 0.0,
  });

  factory Position.fromQuandrantDefault(Quadrant quadrant) {
    switch (quadrant) {
      case Quadrant.LEFT:
        return Position(value: 180.0);
      case Quadrant.CENTER:
        return Position(value: 90.0);
      case Quadrant.EXTREME:
        return Position(value: 270.0);
      case Quadrant.RIGHT:
      default:
        return Position(value: 0.0);
    }
  }

  Quadrant toQuadrant() {
    var angle = value % 360;
    if (angle >= 315.0 || angle <= 45.0) {
      return Quadrant.RIGHT;
    } else if (angle > 45 && angle < 135) {
      return Quadrant.CENTER;
    } else if (angle >= 180 && angle <= 225) {
      return Quadrant.LEFT;
    } else {
      return Quadrant.EXTREME;
    }
  }

  factory Position.fromJson(Map<String, dynamic> json) =>
      _$PositionFromJson(json);

  Map<String, dynamic> toJson() => _$PositionToJson(this);
}

enum Quadrant {
  RIGHT,
  LEFT,
  CENTER,
  EXTREME;

  static Quadrant? fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'right':
        return Quadrant.RIGHT;
      case 'left':
        return Quadrant.LEFT;
      case 'center':
        return Quadrant.CENTER;
      case 'extreme':
        return Quadrant.EXTREME;
      default:
        return null;
    }
  }

  Color get color {
    switch (this) {
      case Quadrant.RIGHT:
        return Palette.red;
      case Quadrant.LEFT:
        return Palette.blue;
      case Quadrant.CENTER:
        return Palette.green;
      case Quadrant.EXTREME:
        return Palette.purple;
    }
  }
}
