import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:political_think/common/models/political_position.dart';

part 'score.g.dart';

@JsonSerializable()
class Score {
  final Map<String, double> values;
  final String? reason;
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  Timestamp updatedAt;

  Score({
    required this.values,
    this.reason,
    required this.updatedAt,
  });

  factory Score.fromJson(Map<String, dynamic> json) => _$ScoreFromJson(json);

  Map<String, dynamic> toJson() => _$ScoreToJson(this);

  static Timestamp _timestampFromJson(int milliseconds) =>
      Timestamp.fromMillisecondsSinceEpoch(milliseconds);
  static dynamic _timestampToJson(Timestamp timestamp) =>
      timestamp.millisecondsSinceEpoch;
}
