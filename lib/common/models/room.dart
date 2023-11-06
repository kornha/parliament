import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:political_think/common/models/position.dart';
import 'package:political_think/common/models/zuser.dart';

part 'room.g.dart';

enum RoomStatus { DRAFT, PUBLISHED }

@JsonSerializable()
class Room {
  final String rid;
  final String pid;
  List<String> messages;
  List<String> users;
  List<String> leftUsers;
  List<String> rightUsers;

  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  Timestamp createdAt;
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  Timestamp updatedAt;

  Room({
    required this.rid,
    required this.pid,
    this.users = const [],
    this.leftUsers = const [],
    this.rightUsers = const [],
    this.messages = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Position? getUserPosition(String uid) {
    if (leftUsers.contains(uid) && !rightUsers.contains(uid)) {
      return Position.fromQuandrantDefault(Quadrant.LEFT);
    } else if (rightUsers.contains(uid) && !leftUsers.contains(uid)) {
      return Position.fromQuandrantDefault(Quadrant.RIGHT);
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
