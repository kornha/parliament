// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Post _$PostFromJson(Map<String, dynamic> json) => Post(
      pid: json['pid'] as String,
      status: $enumDecode(_$PostStatusEnumMap, json['status']),
      createdAt: Utils.timestampFromJson(json['createdAt'] as int),
      updatedAt: Utils.timestampFromJson(json['updatedAt'] as int),
      sourceType: $enumDecode(_$SourceTypeEnumMap, json['sourceType']),
      sourceCreatedAt:
          Utils.timestampFromJsonNullable(json['sourceCreatedAt'] as int?),
      eid: json['eid'] as String?,
      sid: json['sid'] as String?,
      xid: json['xid'] as String?,
      title: json['title'] as String?,
      description: json['description'] as String?,
      body: json['body'] as String?,
      poster: json['poster'] as String?,
      sids:
          (json['sids'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      cids:
          (json['cids'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      url: json['url'] as String?,
      photo: json['photo'] == null
          ? null
          : Photo.fromJson(json['photo'] as Map<String, dynamic>),
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
      'sids': instance.sids,
      'cids': instance.cids,
      'eid': instance.eid,
      'xid': instance.xid,
      'poster': instance.poster,
      'status': _$PostStatusEnumMap[instance.status]!,
      'title': instance.title,
      'description': instance.description,
      'body': instance.body,
      'photo': instance.photo?.toJson(),
      'url': instance.url,
      'sourceType': _$SourceTypeEnumMap[instance.sourceType]!,
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
      'createdAt': Utils.timestampToJson(instance.createdAt),
      'updatedAt': Utils.timestampToJson(instance.updatedAt),
      'sourceCreatedAt':
          Utils.timestampToJsonNullable(instance.sourceCreatedAt),
    };

const _$PostStatusEnumMap = {
  PostStatus.scraping: 'scraping',
  PostStatus.draft: 'draft',
  PostStatus.published: 'published',
  PostStatus.deleted: 'deleted',
  PostStatus.error: 'error',
};

const _$SourceTypeEnumMap = {
  SourceType.article: 'article',
  SourceType.x: 'x',
};
