import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'story.g.dart';

@JsonSerializable(explicitToJson: true)
class Story {
  final String sid;
  String title;
  String description;
  double? importance;
  List<String> locations;

  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  Timestamp createdAt;
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  Timestamp updatedAt;

  Story({
    required this.sid,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    this.importance,
    this.locations = const [],
  });

  factory Story.fromJson(Map<String, dynamic> json) => _$StoryFromJson(json);

  Map<String, dynamic> toJson() => _$StoryToJson(this);

  static Timestamp _timestampFromJson(int milliseconds) =>
      Timestamp.fromMillisecondsSinceEpoch(milliseconds);
  static dynamic _timestampToJson(Timestamp timestamp) =>
      timestamp.millisecondsSinceEpoch;
}
