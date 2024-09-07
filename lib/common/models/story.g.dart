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
      headline: json['headline'] as String?,
      subHeadline: json['subHeadline'] as String?,
      importance: (json['importance'] as num?)?.toDouble(),
      avgReplies: (json['avgReplies'] as num?)?.toDouble(),
      avgReposts: (json['avgReposts'] as num?)?.toDouble(),
      avgLikes: (json['avgLikes'] as num?)?.toDouble(),
      avgBookmarks: (json['avgBookmarks'] as num?)?.toDouble(),
      avgViews: (json['avgViews'] as num?)?.toDouble(),
      pids:
          (json['pids'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      stids:
          (json['stids'] as List<dynamic>?)?.map((e) => e as String).toList() ??
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
      'headline': instance.headline,
      'subHeadline': instance.subHeadline,
      'importance': instance.importance,
      'pids': instance.pids,
      'stids': instance.stids,
      'location': instance.location?.toJson(),
      'photos': instance.photos.map((e) => e.toJson()).toList(),
      'avgReplies': instance.avgReplies,
      'avgReposts': instance.avgReposts,
      'avgLikes': instance.avgLikes,
      'avgBookmarks': instance.avgBookmarks,
      'avgViews': instance.avgViews,
      'createdAt': Utils.timestampToJson(instance.createdAt),
      'updatedAt': Utils.timestampToJson(instance.updatedAt),
      'happenedAt': Utils.timestampToJsonNullable(instance.happenedAt),
    };
