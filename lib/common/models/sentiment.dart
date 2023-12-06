import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:political_think/common/models/political_position.dart';

part 'sentiment.g.dart';

@JsonSerializable(explicitToJson: true)
class Sentiment {
  PoliticalPosition position;

  Sentiment({
    required this.position,
  });

  factory Sentiment.fromJson(Map<String, dynamic> json) =>
      _$SentimentFromJson(json);

  Map<String, dynamic> toJson() => _$SentimentToJson(this);
}
