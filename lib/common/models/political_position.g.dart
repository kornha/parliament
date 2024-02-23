// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'political_position.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PoliticalPosition _$PoliticalPositionFromJson(Map<String, dynamic> json) =>
    PoliticalPosition(
      angle: (json['angle'] as num?)?.toDouble() ?? 90.0,
    );

Map<String, dynamic> _$PoliticalPositionToJson(PoliticalPosition instance) =>
    <String, dynamic>{
      'angle': instance.angle,
    };
