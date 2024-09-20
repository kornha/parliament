import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:political_think/common/models/confidence.dart';
import 'package:political_think/common/models/platform.dart';
import 'package:political_think/common/models/political_position.dart';
import 'package:political_think/common/util/utils.dart';

part 'entity.g.dart';

@JsonSerializable(explicitToJson: true)
class Entity {
  final String eid;
  final String handle;
  final String? photoURL;
  final List<String> pids;
  final List<String> stids;
  final String? plid;
  final Confidence? confidence;
  final Confidence? adminConfidence;
  final PoliticalPosition? bias;
  final PoliticalPosition? adminBias;

  double? avgReplies;
  double? avgReposts;
  double? avgLikes;
  double? avgBookmarks;
  double? avgViews;

  @JsonKey(fromJson: Utils.timestampFromJson, toJson: Utils.timestampToJson)
  Timestamp createdAt;
  @JsonKey(fromJson: Utils.timestampFromJson, toJson: Utils.timestampToJson)
  Timestamp updatedAt;

  Entity({
    required this.eid,
    required this.handle,
    required this.createdAt,
    required this.updatedAt,
    this.avgReplies,
    this.avgReposts,
    this.avgLikes,
    this.avgBookmarks,
    this.avgViews,
    this.photoURL,
    this.pids = const [],
    this.stids = const [],
    this.plid,
    this.confidence,
    this.adminConfidence,
    this.bias,
    this.adminBias,
  });

  factory Entity.fromJson(Map<String, dynamic> json) => _$EntityFromJson(json);

  Map<String, dynamic> toJson() => _$EntityToJson(this);
}
