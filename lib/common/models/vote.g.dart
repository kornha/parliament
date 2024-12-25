// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vote.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Vote _$VoteFromJson(Map<String, dynamic> json) => Vote(
      uid: json['uid'] as String,
      pid: json['pid'] as String,
      bias: json['bias'] == null
          ? null
          : PoliticalPosition.fromJson(json['bias']),
      confidence: json['confidence'] == null
          ? null
          : Confidence.fromJson(json['confidence']),
      reason: json['reason'] as String?,
      type: $enumDecode(_$VoteTypeEnumMap, json['type']),
      createdAt: Vote._timestampFromJson((json['createdAt'] as num).toInt()),
    );

Map<String, dynamic> _$VoteToJson(Vote instance) => <String, dynamic>{
      'uid': instance.uid,
      'pid': instance.pid,
      if (instance.bias?.toJson() case final value?) 'bias': value,
      if (instance.confidence?.toJson() case final value?) 'confidence': value,
      if (instance.reason case final value?) 'reason': value,
      if (Vote._timestampToJson(instance.createdAt) case final value?)
        'createdAt': value,
      'type': _$VoteTypeEnumMap[instance.type]!,
    };

const _$VoteTypeEnumMap = {
  VoteType.bias: 'bias',
  VoteType.confidence: 'confidence',
};
