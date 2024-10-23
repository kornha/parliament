import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:political_think/common/models/confidence.dart';
import 'package:political_think/common/util/utils.dart';

part 'video.g.dart';

@JsonSerializable(explicitToJson: true)
class Video {
  final String videoURL;
  final String? description;
  final bool? llmCompatible;

  Video({
    required this.videoURL,
    this.description,
    this.llmCompatible,
  });

  factory Video.fromJson(Map<String, dynamic> json) => _$VideoFromJson(json);

  Map<String, dynamic> toJson() => _$VideoToJson(this);
}
