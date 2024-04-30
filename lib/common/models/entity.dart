import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:political_think/common/models/bias.dart';
import 'package:political_think/common/models/credibility.dart';
import 'package:political_think/common/models/source_type.dart';
import 'package:political_think/common/util/utils.dart';

part 'entity.g.dart';

@JsonSerializable(explicitToJson: true)
class Entity {
  final String eid;
  final String handle;
  final SourceType sourceType;
  String? photoURL;

  @JsonKey(fromJson: Utils.timestampFromJson, toJson: Utils.timestampToJson)
  Timestamp createdAt;
  @JsonKey(fromJson: Utils.timestampFromJson, toJson: Utils.timestampToJson)
  Timestamp updatedAt;

  Entity({
    required this.eid,
    required this.handle,
    required this.sourceType,
    required this.createdAt,
    required this.updatedAt,
    this.photoURL,
  });

  factory Entity.fromJson(Map<String, dynamic> json) => _$EntityFromJson(json);

  Map<String, dynamic> toJson() => _$EntityToJson(this);
}
