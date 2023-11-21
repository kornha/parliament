import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:political_think/common/models/position.dart';

part 'decision.g.dart';

@JsonSerializable(explicitToJson: true)
class Decision {
  Position winner;
  String reason;

  Decision({
    required this.winner,
    required this.reason,
  });

  factory Decision.fromJson(Map<String, dynamic> json) =>
      _$DecisionFromJson(json);

  Map<String, dynamic> toJson() => _$DecisionToJson(this);
}
