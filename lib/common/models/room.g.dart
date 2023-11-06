// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Room _$RoomFromJson(Map<String, dynamic> json) => Room(
      rid: json['rid'] as String,
      pid: json['pid'] as String,
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
      updatedAt: Room._timestampFromJson(json['updatedAt'] as int),
    );

Map<String, dynamic> _$RoomToJson(Room instance) => <String, dynamic>{
      'rid': instance.rid,
      'pid': instance.pid,
      'messages': instance.messages,
      'users': instance.users,
      'leftUsers': instance.leftUsers,
      'rightUsers': instance.rightUsers,
      'createdAt': Room._timestampToJson(instance.createdAt),
      'updatedAt': Room._timestampToJson(instance.updatedAt),
    };
