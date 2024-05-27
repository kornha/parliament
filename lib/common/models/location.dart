import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:political_think/common/models/political_position.dart';
import 'package:political_think/common/util/utils.dart';

part 'location.g.dart';

@JsonSerializable(explicitToJson: true)
class Location {
  @JsonKey(fromJson: Utils.geoPointFromJson, toJson: Utils.geoPointToJson)
  final GeoPoint geoPoint;
  final String geoHash;

  Location({
    required this.geoPoint,
    required this.geoHash,
  });

  factory Location.fromJson(Map<String, dynamic> json) =>
      _$LocationFromJson(json);

  Map<String, dynamic> toJson() => _$LocationToJson(this);
}
