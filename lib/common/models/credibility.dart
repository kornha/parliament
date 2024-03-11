import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:political_think/common/constants.dart';
import 'package:political_think/common/models/political_position.dart';

part 'credibility.g.dart';

@JsonSerializable(explicitToJson: true)
class Credibility {
  final double value;
  final String? reason;

  Credibility({
    required this.value,
    this.reason,
  });

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

  factory Credibility.fromValue(double value) => Credibility(value: value);

  factory Credibility.fromJson(Map<String, dynamic> json) =>
      _$CredibilityFromJson(json);

  Map<String, dynamic> toJson() => _$CredibilityToJson(this);

  // creates an object with only the credibility value
}
