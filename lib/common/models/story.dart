import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:political_think/common/models/location.dart';
import 'package:political_think/common/models/photo.dart';
import 'package:political_think/common/util/utils.dart';

part 'story.g.dart';

@JsonSerializable(explicitToJson: true)
class Story {
  final String sid;

  String? title; // 2-6 words category
  String? description; // full description of information

  String? headline; // 2-8 words engaging headline
  String? subHeadline; // short engaging description

  double? importance;
  List<String> pids;
  List<String> stids;
  Location? location;
  List<Photo> photos;

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
    this.location,
    this.title,
    this.description,
    this.headline,
    this.subHeadline,
    this.importance,
    this.pids = const [],
    this.stids = const [],
    this.photos = const [],
  });

  factory Story.fromJson(Map<String, dynamic> json) => _$StoryFromJson(json);

  Map<String, dynamic> toJson() => _$StoryToJson(this);
}
