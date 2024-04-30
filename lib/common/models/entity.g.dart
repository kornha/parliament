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
      photoURL: json['photoURL'] as String?,
    );

Map<String, dynamic> _$EntityToJson(Entity instance) => <String, dynamic>{
      'eid': instance.eid,
      'handle': instance.handle,
      'sourceType': _$SourceTypeEnumMap[instance.sourceType]!,
      'photoURL': instance.photoURL,
      'createdAt': Utils.timestampToJson(instance.createdAt),
      'updatedAt': Utils.timestampToJson(instance.updatedAt),
    };

const _$SourceTypeEnumMap = {
  SourceType.article: 'article',
  SourceType.x: 'x',
};
