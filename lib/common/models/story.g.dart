// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'story.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Story _$StoryFromJson(Map<String, dynamic> json) => Story(
      sid: json['sid'] as String,
      createdAt: Utils.timestampFromJson(json['createdAt'] as int),
      updatedAt: Utils.timestampFromJson(json['updatedAt'] as int),
      happenedAt: Utils.timestampFromJsonNullable(json['happenedAt'] as int?),
      location: json['location'] == null
          ? null
          : Location.fromJson(json['location'] as Map<String, dynamic>),
      title: json['title'] as String?,
      description: json['description'] as String?,
      latest: json['latest'] as String?,
      importance: (json['importance'] as num?)?.toDouble(),
      pids:
          (json['pids'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      cids:
          (json['cids'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      photos: (json['photos'] as List<dynamic>?)
              ?.map((e) => Photo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$StoryToJson(Story instance) => <String, dynamic>{
      'sid': instance.sid,
      'title': instance.title,
      'description': instance.description,
      'latest': instance.latest,
      'importance': instance.importance,
      'pids': instance.pids,
      'cids': instance.cids,
      'location': instance.location?.toJson(),
      'photos': instance.photos.map((e) => e.toJson()).toList(),
      'createdAt': Utils.timestampToJson(instance.createdAt),
      'updatedAt': Utils.timestampToJson(instance.updatedAt),
      'happenedAt': Utils.timestampToJsonNullable(instance.happenedAt),
    };
