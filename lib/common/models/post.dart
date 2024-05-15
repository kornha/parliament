import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:political_think/common/models/bias.dart';
import 'package:political_think/common/models/credibility.dart';
import 'package:political_think/common/models/photo.dart';
import 'package:political_think/common/models/source_type.dart';
import 'package:political_think/common/util/utils.dart';

part 'post.g.dart';

enum PostStatus { scraping, draft, published, deleted, error }

@JsonSerializable(explicitToJson: true)
class Post {
  final String pid;
  final String? sid;
  final List<String> sids;
  final List<String> cids;
  // creator domain or handle of the originator TODO: move to entities
  String? eid;
  String? xid; // external id
  // user who posted the post, if any
  String? poster;
  PostStatus status;
  //
  String? title;
  String? description;
  String? body;
  Photo? photo;
  String? url;
  final SourceType sourceType;
  List<String> locations; // currently country codes need to abstract
  //
  int voteCountBias;
  int voteCountCredibility;
  // number of rooms reporting debate scores
  // needed to calculate debateBias
  // can be removed if we change course here
  int debateCountBias;
  // between 0.0 and 359.99
  Bias? userBias;
  Bias? aiBias;
  Bias? debateBias;
  // between 0.0 and 1.0
  Credibility? userCredibility;
  Credibility? aiCredibility;
  // between 0.0 and 1.0
  double? importance;
  //
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
    this.cids = const [],
    this.url,
    this.photo,
    this.locations = const [],
    this.importance,
    this.userBias,
    this.aiBias,
    this.debateBias,
    this.userCredibility,
    this.aiCredibility,
    this.voteCountBias = 0,
    this.voteCountCredibility = 0,
    this.debateCountBias = 0,
  });

  Credibility? get primaryCredibility => aiCredibility ?? userCredibility;
  Bias? get primaryBias => aiBias ?? userBias;

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);

  Map<String, dynamic> toJson() => _$PostToJson(this);
}
