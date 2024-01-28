// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'credibility.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Credibility _$CredibilityFromJson(Map<String, dynamic> json) => Credibility(
      value: (json['value'] as num).toDouble(),
      reason: json['reason'] as String?,
    );

Map<String, dynamic> _$CredibilityToJson(Credibility instance) =>
    <String, dynamic>{
      'value': instance.value,
      'reason': instance.reason,
    };
