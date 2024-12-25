// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clock.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Clock _$ClockFromJson(Map<String, dynamic> json) => Clock(
      duration: (json['duration'] as num).toDouble(),
      increment: (json['increment'] as num?)?.toDouble() ?? 0,
      start: Clock._timestampFromJsonNullable((json['start'] as num?)?.toInt()),
    );

Map<String, dynamic> _$ClockToJson(Clock instance) => <String, dynamic>{
      'duration': instance.duration,
      'increment': instance.increment,
      'start': Clock._timestampToJsonNullable(instance.start),
    };
