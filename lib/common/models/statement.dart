import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:political_think/common/models/confidence.dart';
import 'package:political_think/common/models/political_position.dart';
import 'package:political_think/common/util/utils.dart';

part 'statement.g.dart';

enum StatementType { claim, opinion }

@JsonSerializable(explicitToJson: true)
class Statement {
  final String stid;
  final String value;
  final String? context;
  final List<String> pro;
  final List<String> against;
  final List<String> pids;
  final List<String> sids;
  final List<String> eids;
  final StatementType type;
  final Confidence? confidence;
  final Confidence? adminConfidence;
  final PoliticalPosition? bias;
  final PoliticalPosition? adminBias;

  @JsonKey(fromJson: Utils.timestampFromJson, toJson: Utils.timestampToJson)
  Timestamp statedAt;
  @JsonKey(fromJson: Utils.timestampFromJson, toJson: Utils.timestampToJson)
  Timestamp createdAt;
  @JsonKey(fromJson: Utils.timestampFromJson, toJson: Utils.timestampToJson)
  Timestamp updatedAt;

  Statement({
    required this.stid,
    required this.updatedAt,
    required this.createdAt,
    required this.value,
    required this.statedAt,
    required this.type,
    this.context,
    this.pro = const [],
    this.against = const [],
    this.pids = const [],
    this.sids = const [],
    this.eids = const [],
    this.confidence,
    this.adminConfidence,
    this.bias,
    this.adminBias,
  });

  factory Statement.fromJson(Map<String, dynamic> json) =>
      _$StatementFromJson(json);

  Map<String, dynamic> toJson() => _$StatementToJson(this);
}
