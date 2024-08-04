import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:political_think/common/models/bias.dart';
import 'package:political_think/common/models/credibility.dart';
import 'package:political_think/common/util/utils.dart';

part 'claim.g.dart';

@JsonSerializable(explicitToJson: true)
class Claim {
  final String cid;
  final String value;
  final String? context;
  final List<String> pro;
  final List<String> against;
  final List<String> pids;
  final List<String> sids;

  @JsonKey(fromJson: Utils.timestampFromJson, toJson: Utils.timestampToJson)
  Timestamp claimedAt;
  @JsonKey(fromJson: Utils.timestampFromJson, toJson: Utils.timestampToJson)
  Timestamp createdAt;
  @JsonKey(fromJson: Utils.timestampFromJson, toJson: Utils.timestampToJson)
  Timestamp updatedAt;

  Claim({
    required this.cid,
    required this.updatedAt,
    required this.createdAt,
    required this.value,
    required this.claimedAt,
    this.context,
    this.pro = const [],
    this.against = const [],
    this.pids = const [],
    this.sids = const [],
  });

  factory Claim.fromJson(Map<String, dynamic> json) => _$ClaimFromJson(json);

  Map<String, dynamic> toJson() => _$ClaimToJson(this);
}
