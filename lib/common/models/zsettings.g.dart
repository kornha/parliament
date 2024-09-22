// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'zsettings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ZSettings _$ZSettingsFromJson(Map<String, dynamic> json) => ZSettings(
      minNewsworthiness: json['minNewsworthiness'] == null
          ? null
          : Confidence.fromJson(json['minNewsworthiness']),
    );

Map<String, dynamic> _$ZSettingsToJson(ZSettings instance) => <String, dynamic>{
      'minNewsworthiness': instance.minNewsworthiness?.toJson(),
    };
