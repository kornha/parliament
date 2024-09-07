import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:political_think/common/chat/chat_types/flutter_chat_types.dart'
    as ct;
import 'package:political_think/common/models/vote.dart';

part 'zsettings.g.dart';

@JsonSerializable(explicitToJson: true)
class ZSettings {
  final double minImportance;

  const ZSettings({
    this.minImportance = 0.0,
  });

  factory ZSettings.fromJson(Map<String, dynamic> json) =>
      _$ZSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$ZSettingsToJson(this);
}
