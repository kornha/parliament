// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Video _$VideoFromJson(Map<String, dynamic> json) => Video(
      videoURL: json['videoURL'] as String,
      description: json['description'] as String?,
      llmCompatible: json['llmCompatible'] as bool?,
    );

Map<String, dynamic> _$VideoToJson(Video instance) => <String, dynamic>{
      'videoURL': instance.videoURL,
      'description': instance.description,
      'llmCompatible': instance.llmCompatible,
    };
