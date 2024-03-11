import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:political_think/common/models/political_position.dart';

part 'bias.g.dart';

@JsonSerializable(explicitToJson: true)
class Bias {
  final PoliticalPosition position;
  final String? reason;

  String get name => position.name;
  Color get color => position.color;
  Color get onColor => position.onColor;

  Bias({
    required this.position,
    this.reason,
  });

  factory Bias.fromJson(Map<String, dynamic> json) => _$BiasFromJson(json);

  Map<String, dynamic> toJson() => _$BiasToJson(this);
}
