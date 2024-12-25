// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'platform.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Platform _$PlatformFromJson(Map<String, dynamic> json) => Platform(
      plid: json['plid'] as String,
      url: json['url'] as String,
      createdAt: Utils.timestampFromJson((json['createdAt'] as num).toInt()),
      updatedAt: Utils.timestampFromJson((json['updatedAt'] as num).toInt()),
      avgReplies: (json['avgReplies'] as num?)?.toDouble(),
      avgReposts: (json['avgReposts'] as num?)?.toDouble(),
      avgLikes: (json['avgLikes'] as num?)?.toDouble(),
      avgBookmarks: (json['avgBookmarks'] as num?)?.toDouble(),
      avgViews: (json['avgViews'] as num?)?.toDouble(),
      photoURL: json['photoURL'] as String?,
    );

Map<String, dynamic> _$PlatformToJson(Platform instance) => <String, dynamic>{
      'plid': instance.plid,
      'url': instance.url,
      'photoURL': instance.photoURL,
      'avgReplies': instance.avgReplies,
      'avgReposts': instance.avgReposts,
      'avgLikes': instance.avgLikes,
      'avgBookmarks': instance.avgBookmarks,
      'avgViews': instance.avgViews,
      'createdAt': Utils.timestampToJson(instance.createdAt),
      'updatedAt': Utils.timestampToJson(instance.updatedAt),
    };
