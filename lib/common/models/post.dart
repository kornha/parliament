import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:political_think/common/models/bias.dart';
import 'package:political_think/common/models/credibility.dart';

part 'post.g.dart';

enum PostStatus { draft, published, deleted, error }

enum SourceType { article, x }

@JsonSerializable(explicitToJson: true)
class Post {
  final String pid;
  final String? sid;
  final List<String> sids;
  final List<String> cids;
  // creator domain or handle of the originator TODO: move to entities
  String? creator;
  // user who posted the post, if any
  String? poster;
  PostStatus status;
  //
  String? title;
  String? description;
  String? body;
  String? imageUrl;
  String? url;
  SourceType? sourceType;
  List<String>
      locations; // currently country codes but i want to make this more abstract
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

  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  Timestamp createdAt;
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  Timestamp updatedAt;

  Post({
    required this.pid,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.sid,
    this.title,
    this.description,
    this.body,
    this.creator, // todo, move to entities table!
    this.poster, // uid who posted the post
    this.sids = const [],
    this.cids = const [],
    this.sourceType,
    this.url,
    this.imageUrl,
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

  static Timestamp _timestampFromJson(int milliseconds) =>
      Timestamp.fromMillisecondsSinceEpoch(milliseconds);
  static dynamic _timestampToJson(Timestamp timestamp) =>
      timestamp.millisecondsSinceEpoch;
  static Timestamp? _timestampFromJsonNullable(int? milliseconds) =>
      milliseconds == null
          ? null
          : Timestamp.fromMillisecondsSinceEpoch(milliseconds);
  static dynamic _timestampToJsonNullable(Timestamp? timestamp) =>
      timestamp?.millisecondsSinceEpoch;
}
