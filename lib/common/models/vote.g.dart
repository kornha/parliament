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
          : Bias.fromJson(json['bias'] as Map<String, dynamic>),
      credibility: json['credibility'] == null
          ? null
          : Credibility.fromJson(json['credibility'] as Map<String, dynamic>),
      type: $enumDecode(_$VoteTypeEnumMap, json['type']),
      createdAt: Vote._timestampFromJson(json['createdAt'] as int),
    );

Map<String, dynamic> _$VoteToJson(Vote instance) => <String, dynamic>{
      'uid': instance.uid,
      'pid': instance.pid,
      'bias': instance.bias?.toJson(),
      'credibility': instance.credibility?.toJson(),
      'createdAt': Vote._timestampToJson(instance.createdAt),
      'type': _$VoteTypeEnumMap[instance.type]!,
    };

const _$VoteTypeEnumMap = {
  VoteType.bias: 'bias',
  VoteType.credibility: 'credibility',
};
