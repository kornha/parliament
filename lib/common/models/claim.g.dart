// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'claim.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Claim _$ClaimFromJson(Map<String, dynamic> json) => Claim(
      cid: json['cid'] as String,
      updatedAt: Utils.timestampFromJson(json['updatedAt'] as int),
      createdAt: Utils.timestampFromJson(json['createdAt'] as int),
      value: json['value'] as String,
      claimedAt: Utils.timestampFromJson(json['claimedAt'] as int),
      pro: (json['pro'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const [],
      against: (json['against'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      pids:
          (json['pids'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      sids:
          (json['sids'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
    );

Map<String, dynamic> _$ClaimToJson(Claim instance) => <String, dynamic>{
      'cid': instance.cid,
      'value': instance.value,
      'pro': instance.pro,
      'against': instance.against,
      'pids': instance.pids,
      'sids': instance.sids,
      'claimedAt': Utils.timestampToJson(instance.claimedAt),
      'createdAt': Utils.timestampToJson(instance.createdAt),
      'updatedAt': Utils.timestampToJson(instance.updatedAt),
    };
