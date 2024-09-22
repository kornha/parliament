import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:political_think/common/models/confidence.dart';
import 'package:political_think/common/models/photo.dart';
import 'package:political_think/common/models/platform.dart';
import 'package:political_think/common/models/political_position.dart';
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
  final String? eid;
  final String? xid; // external id
  final String? plid;

  // user who posted the post, if any
  final String? poster;

  final PostStatus status;

  final String? title;
  final String? description;
  final String? body;
  final Photo? photo;
  final Video? video;
  final String? url;
  final List<String> locations;

  final int? replies;
  final int? reposts;
  final int? likes;
  final int? bookmarks;
  final int? views;

  final Confidence? confidence;
  final PoliticalPosition? bias;

  // DEPRECATED!

  final PoliticalPosition? userBias;
  final PoliticalPosition? aiBias;
  final PoliticalPosition? debateBias;

  final Confidence? userConfidence;
  final Confidence? aiConfidence;

  final int voteCountBias;
  final int voteCountConfidence;

  // number of rooms reporting debate scores
  // needed to calculate debateBias
  // can be removed if we change course here
  final int debateCountBias;

  final int?
      messageCount; // not sure if we want to keep this record but we do now

  @JsonKey(fromJson: Utils.timestampFromJson, toJson: Utils.timestampToJson)
  final Timestamp createdAt;
  @JsonKey(fromJson: Utils.timestampFromJson, toJson: Utils.timestampToJson)
  final Timestamp updatedAt;
  @JsonKey(
      fromJson: Utils.timestampFromJsonNullable,
      toJson: Utils.timestampToJsonNullable)
  final Timestamp? sourceCreatedAt;

  Post({
    required this.pid,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    // time the original post was created
    this.sourceCreatedAt,
    this.eid,
    this.sid,
    this.xid,
    this.plid,
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
    this.replies,
    this.reposts,
    this.likes,
    this.bookmarks,
    this.views,
    this.bias,
    this.confidence,
    this.messageCount,
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
