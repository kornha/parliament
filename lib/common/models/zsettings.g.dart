// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'zsettings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ZSettings _$ZSettingsFromJson(Map<String, dynamic> json) => ZSettings(
      minNewsworthiness: json['minNewsworthiness'] == null
          ? const Confidence(value: 0.0)
          : Confidence.fromJson(json['minNewsworthiness']),
      minPosts: (json['minPosts'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$ZSettingsToJson(ZSettings instance) => <String, dynamic>{
      'minNewsworthiness': instance.minNewsworthiness.toJson(),
      'minPosts': instance.minPosts,
    };
