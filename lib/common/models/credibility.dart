import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
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

  factory Credibility.fromValue(double value) => Credibility(value: value);

  factory Credibility.fromJson(Map<String, dynamic> json) =>
      _$CredibilityFromJson(json);

  Map<String, dynamic> toJson() => _$CredibilityToJson(this);

  // creates an object with only the credibility value
}
