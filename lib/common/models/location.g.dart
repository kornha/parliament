// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Location _$LocationFromJson(Map<String, dynamic> json) => Location(
      geoPoint: Utils.geoPointFromJson(json['geoPoint'] as GeoPoint),
      geoHash: json['geoHash'] as String,
    );

Map<String, dynamic> _$LocationToJson(Location instance) => <String, dynamic>{
      'geoPoint': Utils.geoPointToJson(instance.geoPoint),
      'geoHash': instance.geoHash,
    };
