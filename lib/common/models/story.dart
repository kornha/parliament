import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:political_think/common/models/confidence.dart';
import 'package:political_think/common/models/location.dart';
import 'package:political_think/common/models/photo.dart';
import 'package:political_think/common/models/political_position.dart';
import 'package:political_think/common/util/utils.dart';

part 'story.g.dart';

@JsonSerializable(explicitToJson: true)
class Story {
  final String sid;
  final List<String> pids;
  final List<String> stids;
  final List<String> plids;

  final String? title; // 2-6 words category
  final String? description; // full description of information

  final String? headline; // 2-8 words engaging headline
  final String? subHeadline; // short engaging description

  final List<Photo> photos;
  final Location? location;

  final double? avgReplies;
  final double? avgReposts;
  final double? avgLikes;
  final double? avgBookmarks;
  final double? avgViews;

  final PoliticalPosition? bias;
  final Confidence? confidence;

  final Confidence? newsworthiness;

  @JsonKey(fromJson: Utils.timestampFromJson, toJson: Utils.timestampToJson)
  final Timestamp createdAt;
  @JsonKey(fromJson: Utils.timestampFromJson, toJson: Utils.timestampToJson)
  final Timestamp updatedAt;
  @JsonKey(
      fromJson: Utils.timestampFromJsonNullable,
      toJson: Utils.timestampToJsonNullable)
  final Timestamp? happenedAt;

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
    this.avgReplies,
    this.avgReposts,
    this.avgLikes,
    this.avgBookmarks,
    this.avgViews,
    this.newsworthiness,
    this.bias,
    this.confidence,
    this.pids = const [],
    this.stids = const [],
    this.plids = const [],
    this.photos = const [],
  });

  factory Story.fromJson(Map<String, dynamic> json) => _$StoryFromJson(json);

  Map<String, dynamic> toJson() => _$StoryToJson(this);
}
