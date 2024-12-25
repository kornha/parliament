// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'statement.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Statement _$StatementFromJson(Map<String, dynamic> json) => Statement(
      stid: json['stid'] as String,
      updatedAt: Utils.timestampFromJson((json['updatedAt'] as num).toInt()),
      createdAt: Utils.timestampFromJson((json['createdAt'] as num).toInt()),
      value: json['value'] as String,
      statedAt: Utils.timestampFromJson((json['statedAt'] as num).toInt()),
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
      eids:
          (json['eids'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      confidence: json['confidence'] == null
          ? null
          : Confidence.fromJson(json['confidence']),
      adminConfidence: json['adminConfidence'] == null
          ? null
          : Confidence.fromJson(json['adminConfidence']),
      bias: json['bias'] == null
          ? null
          : PoliticalPosition.fromJson(json['bias']),
      adminBias: json['adminBias'] == null
          ? null
          : PoliticalPosition.fromJson(json['adminBias']),
    );

Map<String, dynamic> _$StatementToJson(Statement instance) => <String, dynamic>{
      'stid': instance.stid,
      'value': instance.value,
      'context': instance.context,
      'pro': instance.pro,
      'against': instance.against,
      'pids': instance.pids,
      'sids': instance.sids,
      'eids': instance.eids,
      'type': _$StatementTypeEnumMap[instance.type]!,
      'confidence': instance.confidence?.toJson(),
      'adminConfidence': instance.adminConfidence?.toJson(),
      'bias': instance.bias?.toJson(),
      'adminBias': instance.adminBias?.toJson(),
      'statedAt': Utils.timestampToJson(instance.statedAt),
      'createdAt': Utils.timestampToJson(instance.createdAt),
      'updatedAt': Utils.timestampToJson(instance.updatedAt),
    };

const _$StatementTypeEnumMap = {
  StatementType.claim: 'claim',
  StatementType.opinion: 'opinion',
};
