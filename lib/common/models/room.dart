import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:political_think/common/models/clock.dart';
import 'package:political_think/common/models/political_position.dart';
import 'package:political_think/common/models/score.dart';

part 'room.g.dart';

enum RoomStatus {
  waiting,
  live,
  judging,
  finished,
  errored;

  static List<String> activeStatuses = [waiting.name, live.name];
  bool get isActive => activeStatuses.contains(name);
}

enum RoomParentCollection {
  posts,
  messages;
}

@JsonSerializable(explicitToJson: true)
class Room {
  final String rid;
  final String parentId;
  final RoomParentCollection parentCollection;
  //
  List<String> users;
  // could move this to a map Position.quadrant -> List<String> users
  List<String> leftUsers;
  List<String> rightUsers;
  List<String> centerUsers;
  List<String> extremeUsers;
  //
  int? maxUsers;
  //
  RoomStatus status;
  int? messageCount;
  Clock? clock;
  Score? score;

  // Derived/transactional fields!
  PoliticalPosition? winningPosition;
  List<String>? winners;
  // elo deltas, not full score
  Score? eloScore;
  //
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  Timestamp createdAt;

  Room({
    required this.rid,
    required this.parentId,
    required this.parentCollection,
    required this.status,
    this.users = const [],
    this.leftUsers = const [],
    this.rightUsers = const [],
    this.centerUsers = const [],
    this.extremeUsers = const [],
    this.maxUsers,
    required this.createdAt,
    this.messageCount,
    this.clock,
    this.score,
  });

  PoliticalPosition? getUserPosition(String uid) {
    if (leftUsers.contains(uid)) {
      return PoliticalPosition.left();
    } else if (rightUsers.contains(uid)) {
      return PoliticalPosition.right();
    } else if (centerUsers.contains(uid)) {
      return PoliticalPosition.center();
    } else if (extremeUsers.contains(uid)) {
      return PoliticalPosition.extreme();
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

  double scoreByQuadrant(Quadrant quadrant) {
    switch (quadrant) {
      case Quadrant.left:
        return leftUsers.isEmpty
            ? 0.0
            : leftUsers
                .map((uid) => score?.values[uid] ?? 0)
                .reduce((acc, value) => acc + value);

      case Quadrant.center:
        return centerUsers.isEmpty
            ? 0.0
            : centerUsers
                .map((uid) => score?.values[uid] ?? 0)
                .reduce((acc, value) => acc + value);
      case Quadrant.extreme:
        return extremeUsers.isEmpty
            ? 0.0
            : extremeUsers
                .map((uid) => score?.values[uid] ?? 0)
                .reduce((acc, value) => acc + value);
      case Quadrant.right:
      default:
        return rightUsers.isEmpty
            ? 0.0
            : rightUsers
                .map((uid) => score?.values[uid] ?? 0)
                .reduce((acc, value) => acc + value);
    }
  }

  List<String> usersByQuadrant(Quadrant quadrant) {
    switch (quadrant) {
      case Quadrant.left:
        return leftUsers;
      case Quadrant.center:
        return centerUsers;
      case Quadrant.extreme:
        return extremeUsers;
      case Quadrant.right:
      default:
        return rightUsers;
    }
  }
}
