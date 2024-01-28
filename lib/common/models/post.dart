import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:political_think/common/models/bias.dart';
import 'package:political_think/common/models/credibility.dart';
import 'package:political_think/common/models/political_position.dart';

part 'post.g.dart';

enum PostStatus { draft, published, deleted }

enum SourceType { article, twitter }

@JsonSerializable(explicitToJson: true)
class Post {
  final String pid;
  final String? sid;
  String? creator;
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
  Bias? userBias;
  Bias? aiBias;
  Credibility? userCredibility;
  Credibility? aiCredibility;
  int? importance;
  //
  int? messageCount; // not sure if we want to keep this record but we do now

  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  Timestamp createdAt;
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  Timestamp updatedAt;

  Post({
    required this.pid,
    this.sid,
    this.creator,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.sourceType,
    this.title,
    this.description,
    this.body,
    this.url,
    this.imageUrl,
    this.locations = const [],
    this.importance,
    this.userBias,
    this.aiBias,
    this.userCredibility,
    this.aiCredibility,
    this.voteCountBias = 0,
    this.voteCountCredibility = 0,
  });

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);

  Map<String, dynamic> toJson() => _$PostToJson(this);

  static Timestamp _timestampFromJson(int milliseconds) =>
      Timestamp.fromMillisecondsSinceEpoch(milliseconds);
  static dynamic _timestampToJson(Timestamp timestamp) =>
      timestamp.millisecondsSinceEpoch;
}
