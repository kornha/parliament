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
  writeNotNull('confidence', instance.confidence?.toJson());
  writeNotNull('reason', instance.reason);
  writeNotNull('createdAt', Vote._timestampToJson(instance.createdAt));
  val['type'] = _$VoteTypeEnumMap[instance.type]!;
  return val;
}

const _$VoteTypeEnumMap = {
  VoteType.bias: 'bias',
  VoteType.confidence: 'confidence',
};
