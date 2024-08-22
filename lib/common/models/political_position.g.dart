// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'political_position.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PoliticalPosition _$PoliticalPositionFromJson(Map<String, dynamic> json) =>
    PoliticalPosition(
      angle: json['angle'] == null
          ? 90.0
          : PoliticalPosition._fromJson(json['angle']),
    );

Map<String, dynamic> _$PoliticalPositionToJson(PoliticalPosition instance) =>
    <String, dynamic>{
      'angle': PoliticalPosition._toJson(instance.angle),
    };
