// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'photo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Photo _$PhotoFromJson(Map<String, dynamic> json) => Photo(
      photoURL: json['photoURL'] as String,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$PhotoToJson(Photo instance) => <String, dynamic>{
      'photoURL': instance.photoURL,
      'description': instance.description,
    };
