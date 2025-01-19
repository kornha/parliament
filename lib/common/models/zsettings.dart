import 'package:json_annotation/json_annotation.dart';
import 'package:political_think/common/models/confidence.dart';

part 'zsettings.g.dart';

@JsonSerializable(explicitToJson: true)
class ZSettings {
  final Confidence minNewsworthiness;
  final int minPosts;

  const ZSettings({
    this.minNewsworthiness = const Confidence(value: 0.0),
    this.minPosts = 3,
  });

  factory ZSettings.fromJson(Map<String, dynamic> json) =>
      _$ZSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$ZSettingsToJson(this);
}
