// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Entity _$EntityFromJson(Map<String, dynamic> json) => Entity(
      eid: json['eid'] as String,
      handle: json['handle'] as String,
      sourceType: $enumDecode(_$SourceTypeEnumMap, json['sourceType']),
      createdAt: Utils.timestampFromJson(json['createdAt'] as int),
      updatedAt: Utils.timestampFromJson(json['updatedAt'] as int),
      pids:
          (json['pids'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      stids:
          (json['stids'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      photoURL: json['photoURL'] as String?,
    );

Map<String, dynamic> _$EntityToJson(Entity instance) => <String, dynamic>{
      'eid': instance.eid,
      'handle': instance.handle,
      'sourceType': _$SourceTypeEnumMap[instance.sourceType]!,
      'photoURL': instance.photoURL,
      'pids': instance.pids,
      'stids': instance.stids,
      'createdAt': Utils.timestampToJson(instance.createdAt),
      'updatedAt': Utils.timestampToJson(instance.updatedAt),
    };

const _$SourceTypeEnumMap = {
  SourceType.article: 'article',
  SourceType.x: 'x',
};
