// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'story.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Story _$StoryFromJson(Map<String, dynamic> json) => Story(
      sid: json['sid'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      createdAt: Story._timestampFromJson(json['createdAt'] as int),
      updatedAt: Story._timestampFromJson(json['updatedAt'] as int),
      importance: json['importance'] as int?,
      locations: (json['locations'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$StoryToJson(Story instance) => <String, dynamic>{
      'sid': instance.sid,
      'title': instance.title,
      'description': instance.description,
      'importance': instance.importance,
      'locations': instance.locations,
      'createdAt': Story._timestampToJson(instance.createdAt),
      'updatedAt': Story._timestampToJson(instance.updatedAt),
    };
