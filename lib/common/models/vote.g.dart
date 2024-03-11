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
      reason: json['reason'] as String?,
      type: $enumDecode(_$VoteTypeEnumMap, json['type']),
      createdAt: Vote._timestampFromJson(json['createdAt'] as int),
    );

Map<String, dynamic> _$VoteToJson(Vote instance) {
  final val = <String, dynamic>{
    'uid': instance.uid,
    'pid': instance.pid,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('bias', instance.bias?.toJson());
  writeNotNull('credibility', instance.credibility?.toJson());
  writeNotNull('reason', instance.reason);
  writeNotNull('createdAt', Vote._timestampToJson(instance.createdAt));
  val['type'] = _$VoteTypeEnumMap[instance.type]!;
  return val;
}

const _$VoteTypeEnumMap = {
  VoteType.bias: 'bias',
  VoteType.credibility: 'credibility',
};
