// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Post _$PostFromJson(Map<String, dynamic> json) => Post(
      pid: json['pid'] as String,
      sid: json['sid'] as String?,
      creator: json['creator'] as String?,
      poster: json['poster'] as String?,
      status: $enumDecode(_$PostStatusEnumMap, json['status']),
      createdAt: Post._timestampFromJson(json['createdAt'] as int),
      updatedAt: Post._timestampFromJson(json['updatedAt'] as int),
      sourceType: $enumDecodeNullable(_$SourceTypeEnumMap, json['sourceType']),
      title: json['title'] as String?,
      description: json['description'] as String?,
      body: json['body'] as String?,
      url: json['url'] as String?,
      imageUrl: json['imageUrl'] as String?,
      locations: (json['locations'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      importance: (json['importance'] as num?)?.toDouble(),
      userBias: json['userBias'] == null
          ? null
          : Bias.fromJson(json['userBias'] as Map<String, dynamic>),
      aiBias: json['aiBias'] == null
          ? null
          : Bias.fromJson(json['aiBias'] as Map<String, dynamic>),
      debateBias: json['debateBias'] == null
          ? null
          : Bias.fromJson(json['debateBias'] as Map<String, dynamic>),
      userCredibility: json['userCredibility'] == null
          ? null
          : Credibility.fromJson(
              json['userCredibility'] as Map<String, dynamic>),
      aiCredibility: json['aiCredibility'] == null
          ? null
          : Credibility.fromJson(json['aiCredibility'] as Map<String, dynamic>),
      voteCountBias: json['voteCountBias'] as int? ?? 0,
      voteCountCredibility: json['voteCountCredibility'] as int? ?? 0,
      debateCountBias: json['debateCountBias'] as int? ?? 0,
    )..messageCount = json['messageCount'] as int?;

Map<String, dynamic> _$PostToJson(Post instance) => <String, dynamic>{
      'pid': instance.pid,
      'sid': instance.sid,
      'creator': instance.creator,
      'poster': instance.poster,
      'status': _$PostStatusEnumMap[instance.status]!,
      'title': instance.title,
      'description': instance.description,
      'body': instance.body,
      'imageUrl': instance.imageUrl,
      'url': instance.url,
      'sourceType': _$SourceTypeEnumMap[instance.sourceType],
      'locations': instance.locations,
      'voteCountBias': instance.voteCountBias,
      'voteCountCredibility': instance.voteCountCredibility,
      'debateCountBias': instance.debateCountBias,
      'userBias': instance.userBias?.toJson(),
      'aiBias': instance.aiBias?.toJson(),
      'debateBias': instance.debateBias?.toJson(),
      'userCredibility': instance.userCredibility?.toJson(),
      'aiCredibility': instance.aiCredibility?.toJson(),
      'importance': instance.importance,
      'messageCount': instance.messageCount,
      'createdAt': Post._timestampToJson(instance.createdAt),
      'updatedAt': Post._timestampToJson(instance.updatedAt),
    };

const _$PostStatusEnumMap = {
  PostStatus.draft: 'draft',
  PostStatus.published: 'published',
  PostStatus.deleted: 'deleted',
  PostStatus.error: 'error',
};

const _$SourceTypeEnumMap = {
  SourceType.article: 'article',
  SourceType.x: 'x',
};
