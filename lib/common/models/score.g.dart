// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'score.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Score _$ScoreFromJson(Map<String, dynamic> json) => Score(
      values: (json['values'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
      reason: json['reason'] as String?,
      updatedAt: Score._timestampFromJson((json['updatedAt'] as num).toInt()),
    );

Map<String, dynamic> _$ScoreToJson(Score instance) => <String, dynamic>{
      'values': instance.values,
      'reason': instance.reason,
      'updatedAt': Score._timestampToJson(instance.updatedAt),
    };
