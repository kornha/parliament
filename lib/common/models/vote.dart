import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:political_think/common/chat/chat_types/flutter_chat_types.dart'
    as ct;
import 'package:political_think/common/models/bias.dart';
import 'package:political_think/common/models/credibility.dart';
import 'package:political_think/common/models/political_position.dart';

part 'vote.g.dart';

enum VoteType {
  bias,
  credibility;

  String get collectionName =>
      "votes${name[0].toUpperCase()}${name.substring(1).toLowerCase()}";
}

// TODO: BEWARE! INCLUDEIFNULL: FALSE is only used here,
// this is needed because of how we do the vote() function in the frontend
// which is used as an "update" pattern
// which can accidentally overwrite fields with null
@JsonSerializable(explicitToJson: true, includeIfNull: false)
@JsonSerializable()
class Vote {
  final String uid; // this is the docId of the vote
  final String pid;
  Bias? bias;
  Credibility? credibility;
  String? reason;
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  Timestamp createdAt;
  VoteType type;

  Vote({
    required this.uid,
    required this.pid, // only needed to override == afaik
    this.bias,
    this.credibility,
    this.reason,
    required this.type,
    required this.createdAt,
  });

  factory Vote.fromJson(Map<String, dynamic> json) => _$VoteFromJson(json);

  Map<String, dynamic> toJson() => _$VoteToJson(this);

  static Timestamp _timestampFromJson(int milliseconds) =>
      Timestamp.fromMillisecondsSinceEpoch(milliseconds);
  static dynamic _timestampToJson(Timestamp timestamp) =>
      timestamp.millisecondsSinceEpoch;

  @override
  bool operator ==(other) =>
      other is Vote &&
      uid == other.uid &&
      pid == other.pid &&
      bias?.position == other.bias?.position &&
      credibility?.value == other.credibility?.value &&
      type == other.type &&
      createdAt == other.createdAt;
  @override
  int get hashCode => Object.hash(uid, pid, bias, credibility, createdAt);
}
