// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bias.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Bias _$BiasFromJson(Map<String, dynamic> json) => Bias(
      position:
          PoliticalPosition.fromJson(json['position'] as Map<String, dynamic>),
      reason: json['reason'] as String?,
    );

Map<String, dynamic> _$BiasToJson(Bias instance) => <String, dynamic>{
      'position': instance.position.toJson(),
      'reason': instance.reason,
    };
