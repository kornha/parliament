import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:political_think/common/models/confidence.dart';
import 'package:political_think/common/models/photo.dart';
import 'package:political_think/common/models/political_position.dart';
import 'package:political_think/common/models/source_type.dart';
import 'package:political_think/common/models/video.dart';
import 'package:political_think/common/util/utils.dart';

part 'post.g.dart';

enum PostStatus {
  scraping,
  draft,
  published,
  finding, // finding stories and claims
  found, // found stories and claims
  //
  unsupported
}

@JsonSerializable(explicitToJson: true)
class Post {
  final String pid;
  final String? sid;
  final List<String> sids;
  final List<String> stids;

  String? eid;
  String? xid; // external id

  // user who posted the post, if any
  String? poster;

  PostStatus status;

  String? title;
  String? description;
  String? body;
  Photo? photo;
  Video? video;
  String? url;
  SourceType sourceType;
  List<String> locations;

  int? replies;
  int? reposts;
  int? likes;
  int? bookmarks;
  int? views;

  // DEPRECATED!

  PoliticalPosition? userBias;
  PoliticalPosition? aiBias;
  PoliticalPosition? debateBias;

  Confidence? userConfidence;
  Confidence? aiConfidence;

  int voteCountBias;
  int voteCountConfidence;

  // number of rooms reporting debate scores
  // needed to calculate debateBias
  // can be removed if we change course here
  int debateCountBias;

  double? importance;

  int? messageCount; // not sure if we want to keep this record but we do now

  @JsonKey(fromJson: Utils.timestampFromJson, toJson: Utils.timestampToJson)
  Timestamp createdAt;
  @JsonKey(fromJson: Utils.timestampFromJson, toJson: Utils.timestampToJson)
  Timestamp updatedAt;
  @JsonKey(
      fromJson: Utils.timestampFromJsonNullable,
      toJson: Utils.timestampToJsonNullable)
  Timestamp? sourceCreatedAt;

  Post({
    required this.pid,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    // time the original post was created
    required this.sourceType,
    this.sourceCreatedAt,
    this.eid,
    this.sid,
    this.xid,
    this.title,
    this.description,
    this.body,
    this.poster, // uid who posted the post
    this.sids = const [],
    this.stids = const [],
    this.url,
    this.photo,
    this.video,
    this.locations = const [],
    this.importance,
    this.userBias,
    this.aiBias,
    this.debateBias,
    this.userConfidence,
    this.aiConfidence,
    this.voteCountBias = 0,
    this.voteCountConfidence = 0,
    this.debateCountBias = 0,
  });

  Confidence? get primaryConfidence => aiConfidence ?? userConfidence;
  PoliticalPosition? get primaryBias => aiBias ?? userBias;

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);

  Map<String, dynamic> toJson() => _$PostToJson(this);
}
