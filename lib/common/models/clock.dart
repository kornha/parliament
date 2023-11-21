import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'clock.g.dart';

@JsonSerializable()
class Clock {
  double duration;
  double increment;
  @JsonKey(
      fromJson: _timestampFromJsonNullable, toJson: _timestampToJsonNullable)
  Timestamp? start;
  Timestamp? get end => start == null
      ? null
      : Timestamp.fromMillisecondsSinceEpoch(
          start!.millisecondsSinceEpoch + (duration * 1000).toInt());

  bool? get isOver =>
      DateTime.now().isAtSameMomentAs(end!.toDate()) ||
      DateTime.now().isAfter(end!.toDate());

  Clock({
    required this.duration,
    this.increment = 0,
    this.start,
  });

  factory Clock.fromJson(Map<String, dynamic> json) => _$ClockFromJson(json);

  Map<String, dynamic> toJson() => _$ClockToJson(this);

  // TODO: Hack
  static Timestamp? _timestampFromJsonNullable(int? milliseconds) =>
      milliseconds == null
          ? null
          : Timestamp.fromMillisecondsSinceEpoch(milliseconds);
  static dynamic _timestampToJsonNullable(Timestamp? timestamp) =>
      timestamp?.millisecondsSinceEpoch;
}
