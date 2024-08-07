// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'statement.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Statement _$StatementFromJson(Map<String, dynamic> json) => Statement(
      stid: json['stid'] as String,
      updatedAt: Utils.timestampFromJson(json['updatedAt'] as int),
      createdAt: Utils.timestampFromJson(json['createdAt'] as int),
      value: json['value'] as String,
      statedAt: Utils.timestampFromJson(json['statedAt'] as int),
      type: $enumDecode(_$StatementTypeEnumMap, json['type']),
      context: json['context'] as String?,
      pro: (json['pro'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const [],
      against: (json['against'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      pids:
          (json['pids'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      sids:
          (json['sids'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
    );

Map<String, dynamic> _$StatementToJson(Statement instance) => <String, dynamic>{
      'stid': instance.stid,
      'value': instance.value,
      'context': instance.context,
      'pro': instance.pro,
      'against': instance.against,
      'pids': instance.pids,
      'sids': instance.sids,
      'type': _$StatementTypeEnumMap[instance.type]!,
      'statedAt': Utils.timestampToJson(instance.statedAt),
      'createdAt': Utils.timestampToJson(instance.createdAt),
      'updatedAt': Utils.timestampToJson(instance.updatedAt),
    };

const _$StatementTypeEnumMap = {
  StatementType.claim: 'claim',
  StatementType.opinion: 'opinion',
};
