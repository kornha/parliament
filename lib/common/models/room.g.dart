// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Room _$RoomFromJson(Map<String, dynamic> json) => Room(
      rid: json['rid'] as String,
      parentId: json['parentId'] as String,
      parentCollection:
          $enumDecode(_$RoomParentCollectionEnumMap, json['parentCollection']),
      status: $enumDecode(_$RoomStatusEnumMap, json['status']),
      users:
          (json['users'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      leftUsers: (json['leftUsers'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      rightUsers: (json['rightUsers'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      centerUsers: (json['centerUsers'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      extremeUsers: (json['extremeUsers'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      maxUsers: json['maxUsers'] as int?,
      createdAt: Room._timestampFromJson(json['createdAt'] as int),
      messageCount: json['messageCount'] as int?,
      clock: json['clock'] == null
          ? null
          : Clock.fromJson(json['clock'] as Map<String, dynamic>),
      score: json['score'] == null
          ? null
          : Score.fromJson(json['score'] as Map<String, dynamic>),
    )
      ..winningPosition = json['winningPosition'] == null
          ? null
          : PoliticalPosition.fromJson(json['winningPosition'])
      ..winners =
          (json['winners'] as List<dynamic>?)?.map((e) => e as String).toList()
      ..eloScore = json['eloScore'] == null
          ? null
          : Score.fromJson(json['eloScore'] as Map<String, dynamic>);

Map<String, dynamic> _$RoomToJson(Room instance) => <String, dynamic>{
      'rid': instance.rid,
      'parentId': instance.parentId,
      'parentCollection':
          _$RoomParentCollectionEnumMap[instance.parentCollection]!,
      'users': instance.users,
      'leftUsers': instance.leftUsers,
      'rightUsers': instance.rightUsers,
      'centerUsers': instance.centerUsers,
      'extremeUsers': instance.extremeUsers,
      'maxUsers': instance.maxUsers,
      'status': _$RoomStatusEnumMap[instance.status]!,
      'messageCount': instance.messageCount,
      'clock': instance.clock?.toJson(),
      'score': instance.score?.toJson(),
      'winningPosition': instance.winningPosition?.toJson(),
      'winners': instance.winners,
      'eloScore': instance.eloScore?.toJson(),
      'createdAt': Room._timestampToJson(instance.createdAt),
    };

const _$RoomParentCollectionEnumMap = {
  RoomParentCollection.posts: 'posts',
  RoomParentCollection.messages: 'messages',
};

const _$RoomStatusEnumMap = {
  RoomStatus.waiting: 'waiting',
  RoomStatus.live: 'live',
  RoomStatus.judging: 'judging',
  RoomStatus.finished: 'finished',
  RoomStatus.errored: 'errored',
};
