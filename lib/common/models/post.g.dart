// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Post _$PostFromJson(Map<String, dynamic> json) => Post(
      pid: json['pid'] as String,
      creator: json['creator'] as String,
      status: $enumDecode(_$PostStatusEnumMap, json['status']),
      createdAt: Post._timestampFromJson(json['createdAt'] as int),
      updatedAt: Post._timestampFromJson(json['updatedAt'] as int),
      title: json['title'] as String?,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      url: json['url'] as String?,
    );

Map<String, dynamic> _$PostToJson(Post instance) => <String, dynamic>{
      'pid': instance.pid,
      'creator': instance.creator,
      'status': _$PostStatusEnumMap[instance.status]!,
      'title': instance.title,
      'description': instance.description,
      'imageUrl': instance.imageUrl,
      'url': instance.url,
      'createdAt': Post._timestampToJson(instance.createdAt),
      'updatedAt': Post._timestampToJson(instance.updatedAt),
    };

const _$PostStatusEnumMap = {
  PostStatus.draft: 'draft',
  PostStatus.published: 'published',
};
