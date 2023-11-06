// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'partial_custom.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PartialCustom _$PartialCustomFromJson(Map<String, dynamic> json) =>
    PartialCustom(
      metadata: json['metadata'] as Map<String, dynamic>?,
      repliedMessage: json['repliedMessage'] == null
          ? null
          : Message.fromJson(json['repliedMessage'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PartialCustomToJson(PartialCustom instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('metadata', instance.metadata);
  writeNotNull('repliedMessage', instance.repliedMessage?.toJson());
  return val;
}
