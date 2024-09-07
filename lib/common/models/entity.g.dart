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
      avgReplies: (json['avgReplies'] as num?)?.toDouble(),
      avgReposts: (json['avgReposts'] as num?)?.toDouble(),
      avgLikes: (json['avgLikes'] as num?)?.toDouble(),
      avgBookmarks: (json['avgBookmarks'] as num?)?.toDouble(),
      avgViews: (json['avgViews'] as num?)?.toDouble(),
      photoURL: json['photoURL'] as String?,
      pids:
          (json['pids'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      stids:
          (json['stids'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      confidence: json['confidence'] == null
          ? null
          : Confidence.fromJson(json['confidence']),
      adminConfidence: json['adminConfidence'] == null
          ? null
          : Confidence.fromJson(json['adminConfidence']),
      bias: json['bias'] == null
          ? null
          : PoliticalPosition.fromJson(json['bias']),
      adminBias: json['adminBias'] == null
          ? null
          : PoliticalPosition.fromJson(json['adminBias']),
    );

Map<String, dynamic> _$EntityToJson(Entity instance) => <String, dynamic>{
      'eid': instance.eid,
      'handle': instance.handle,
      'sourceType': _$SourceTypeEnumMap[instance.sourceType]!,
      'photoURL': instance.photoURL,
      'pids': instance.pids,
      'stids': instance.stids,
      'confidence': instance.confidence?.toJson(),
      'adminConfidence': instance.adminConfidence?.toJson(),
      'bias': instance.bias?.toJson(),
      'adminBias': instance.adminBias?.toJson(),
      'avgReplies': instance.avgReplies,
      'avgReposts': instance.avgReposts,
      'avgLikes': instance.avgLikes,
      'avgBookmarks': instance.avgBookmarks,
      'avgViews': instance.avgViews,
      'createdAt': Utils.timestampToJson(instance.createdAt),
      'updatedAt': Utils.timestampToJson(instance.updatedAt),
    };

const _$SourceTypeEnumMap = {
  SourceType.article: 'article',
  SourceType.x: 'x',
};
