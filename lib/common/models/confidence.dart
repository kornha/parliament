import 'package:flutter/material.dart';
import 'package:political_think/common/constants.dart';

// Json serialization not used here
class Confidence {
  final double value;

  const Confidence({
    required this.value,
  });

  // Operator overloading to enable arithmetic operations
  Confidence operator +(Confidence other) {
    return Confidence(value: value + other.value);
  }

  Confidence operator -(Confidence other) {
    return Confidence(value: value - other.value);
  }

  Confidence operator *(Confidence other) {
    return Confidence(value: value * other.value);
  }

  Confidence operator /(Confidence other) {
    return Confidence(value: value / other.value);
  }

  // >, <, >=, <= operators
  bool operator >(Confidence other) => value > other.value;
  bool operator <(Confidence other) => value < other.value;
  bool operator >=(Confidence other) => value >= other.value;
  bool operator <=(Confidence other) => value <= other.value;

  @override
  String toString() => value.toStringAsFixed(2);

  @override
  bool operator ==(other) => other is Confidence && value == other.value;
  @override
  int get hashCode => value.hashCode;

  // Additional methods
  String get name => value > 0.9
      ? "Credible"
      : value > 0.75
          ? "Mostly Credible"
          : value > 0.5
              ? "Possibly Credible"
              : value > 0.25
                  ? "Not Credible"
                  : "Fake";

  Color get color => Color.fromRGBO(
        value < 0.5 ? 255 * (1.0 - value) ~/ 1.0 : 0,
        value >= 0.5 ? 255 * value ~/ 1.0 : 0,
        255 * (1.0 - value) ~/ 1.0,
        1.0,
      );

  Color get onColor => Palette.black;

  factory Confidence.base() {
    return const Confidence(value: 0.5);
  }

  factory Confidence.min() {
    return const Confidence(value: 0.0);
  }

  factory Confidence.max() {
    return const Confidence(value: 1.0);
  }

  // Custom JSON serialization/deserialization
  factory Confidence.fromJson(dynamic json) {
    if (json is int) {
      return Confidence(value: json.toDouble());
    }
    return Confidence(value: json as double);
  }

  dynamic toJson() => value;
}
