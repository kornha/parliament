import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:political_think/common/models/bias.dart';
import 'package:political_think/common/models/credibility.dart';
import 'package:political_think/common/util/utils.dart';

part 'photo.g.dart';

@JsonSerializable(explicitToJson: true)
class Photo {
  final String photoURL;
  final String? description;

  Photo({
    required this.photoURL,
    this.description,
  });

  factory Photo.fromJson(Map<String, dynamic> json) => _$PhotoFromJson(json);

  Map<String, dynamic> toJson() => _$PhotoToJson(this);
}
