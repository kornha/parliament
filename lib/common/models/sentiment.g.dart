// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sentiment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Sentiment _$SentimentFromJson(Map<String, dynamic> json) => Sentiment(
      position:
          PoliticalPosition.fromJson(json['position'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SentimentToJson(Sentiment instance) => <String, dynamic>{
      'position': instance.position.toJson(),
    };
