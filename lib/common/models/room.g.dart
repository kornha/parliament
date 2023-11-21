// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Room _$RoomFromJson(Map<String, dynamic> json) => Room(
      rid: json['rid'] as String,
      pid: json['pid'] as String,
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
      messages: (json['messages'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      createdAt: Room._timestampFromJson(json['createdAt'] as int),
      messageCount: json['messageCount'] as int?,
      clock: json['clock'] == null
          ? null
          : Clock.fromJson(json['clock'] as Map<String, dynamic>),
      decision: json['decision'] == null
          ? null
          : Decision.fromJson(json['decision'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$RoomToJson(Room instance) => <String, dynamic>{
      'rid': instance.rid,
      'pid': instance.pid,
      'messages': instance.messages,
      'users': instance.users,
      'leftUsers': instance.leftUsers,
      'rightUsers': instance.rightUsers,
      'status': _$RoomStatusEnumMap[instance.status]!,
      'messageCount': instance.messageCount,
      'clock': instance.clock?.toJson(),
      'decision': instance.decision?.toJson(),
      'createdAt': Room._timestampToJson(instance.createdAt),
    };

const _$RoomStatusEnumMap = {
  RoomStatus.waiting: 'waiting',
  RoomStatus.locked: 'locked',
  RoomStatus.live: 'live',
  RoomStatus.judging: 'judging',
  RoomStatus.finished: 'finished',
  RoomStatus.errored: 'errored',
};
