// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'decision.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Decision _$DecisionFromJson(Map<String, dynamic> json) => Decision(
      winner: Position.fromJson(json['winner'] as Map<String, dynamic>),
      reason: json['reason'] as String,
    );

Map<String, dynamic> _$DecisionToJson(Decision instance) => <String, dynamic>{
      'winner': instance.winner.toJson(),
      'reason': instance.reason,
    };
