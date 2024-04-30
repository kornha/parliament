import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:political_think/common/util/utils.dart';

part 'story.g.dart';

@JsonSerializable(explicitToJson: true)
class Story {
  final String sid;
  String? title;
  String? description;
  double? importance;
  List<String> pids;
  List<String> cids;
  List<String> locations;

  @JsonKey(fromJson: Utils.timestampFromJson, toJson: Utils.timestampToJson)
  Timestamp createdAt;
  @JsonKey(fromJson: Utils.timestampFromJson, toJson: Utils.timestampToJson)
  Timestamp updatedAt;
  @JsonKey(
      fromJson: Utils.timestampFromJsonNullable,
      toJson: Utils.timestampToJsonNullable)
  Timestamp? happenedAt;

  Story({
    required this.sid,
    required this.createdAt,
    required this.updatedAt,
    this.happenedAt,
    this.title,
    this.description,
    this.importance,
    this.locations = const [],
    this.pids = const [],
    this.cids = const [],
  });

  factory Story.fromJson(Map<String, dynamic> json) => _$StoryFromJson(json);

  Map<String, dynamic> toJson() => _$StoryToJson(this);
}
