import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:political_think/common/models/clock.dart';
import 'package:political_think/common/models/decision.dart';
import 'package:political_think/common/models/political_position.dart';
import 'package:political_think/common/models/zuser.dart';

part 'room.g.dart';

enum RoomStatus { waiting, locked, live, judging, finished, errored }

@JsonSerializable(explicitToJson: true)
class Room {
  final String rid;
  final String pid;
  List<String> messages;
  List<String> users;
  List<String> leftUsers;
  List<String> rightUsers;
  RoomStatus status;
  int? messageCount;
  Clock? clock;
  Decision? decision;

  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  Timestamp createdAt;

  Room({
    required this.rid,
    required this.pid,
    required this.status,
    this.users = const [],
    this.leftUsers = const [],
    this.rightUsers = const [],
    this.messages = const [],
    required this.createdAt,
    this.messageCount,
    this.clock,
    this.decision,
  });

  PoliticalPosition? getUserPosition(String uid) {
    if (leftUsers.contains(uid) && !rightUsers.contains(uid)) {
      return PoliticalPosition.fromQuandrant(Quadrant.left);
    } else if (rightUsers.contains(uid) && !leftUsers.contains(uid)) {
      return PoliticalPosition.fromQuandrant(Quadrant.right);
    } else {
      return null;
    }
  }

  factory Room.fromJson(Map<String, dynamic> json) => _$RoomFromJson(json);

  Map<String, dynamic> toJson() => _$RoomToJson(this);

  static Timestamp _timestampFromJson(int milliseconds) =>
      Timestamp.fromMillisecondsSinceEpoch(milliseconds);
  static dynamic _timestampToJson(Timestamp timestamp) =>
      timestamp.millisecondsSinceEpoch;
}
