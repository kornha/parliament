import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:political_think/common/models/political_position.dart';

import '../message.dart';
import '../preview_data.dart' show PreviewData;
import '../user.dart' show User;
import 'partial_text.dart';

part 'text_message.g.dart';

/// A class that represents text message.
@JsonSerializable(explicitToJson: true)
@immutable
abstract class TextMessage extends Message {
  /// Creates a text message.
  const TextMessage._({
    required super.author,
    super.createdAt,
    required super.id,
    super.metadata,
    this.previewData,
    super.remoteId,
    super.repliedMessage,
    super.roomId,
    super.showStatus,
    super.status,
    required this.text,
    MessageType? type,
    super.updatedAt,
    super.position,
  }) : super(type: type ?? MessageType.text);

  const factory TextMessage({
    required User author,
    int? createdAt,
    required String id,
    Map<String, dynamic>? metadata,
    PreviewData? previewData,
    String? remoteId,
    Message? repliedMessage,
    String? roomId,
    bool? showStatus,
    Status? status,
    required String text,
    MessageType? type,
    int? updatedAt,
    PoliticalPosition? position,
  }) = _TextMessage;

  /// Creates a text message from a map (decoded JSON).
  factory TextMessage.fromJson(Map<String, dynamic> json) =>
      _$TextMessageFromJson(json);

  /// Creates a full text message from a partial one.
  factory TextMessage.fromPartial({
    required User author,
    int? createdAt,
    required String id,
    required PartialText partialText,
    String? remoteId,
    String? roomId,
    bool? showStatus,
    Status? status,
    int? updatedAt,
    PoliticalPosition? position,
  }) =>
      _TextMessage(
        author: author,
        createdAt: createdAt,
        id: id,
        metadata: partialText.metadata,
        previewData: partialText.previewData,
        remoteId: remoteId,
        repliedMessage: partialText.repliedMessage,
        roomId: roomId,
        showStatus: showStatus,
        status: status,
        text: partialText.text,
        type: MessageType.text,
        updatedAt: updatedAt,
        position: position,
      );

  /// See [PreviewData].
  final PreviewData? previewData;

  /// User's message.
  final String text;

  /// Equatable props.
  @override
  List<Object?> get props => [
        author,
        createdAt,
        id,
        metadata,
        previewData,
        remoteId,
        repliedMessage,
        roomId,
        showStatus,
        status,
        text,
        updatedAt,
        position,
      ];

  @override
  Message copyWith({
    User? author,
    int? createdAt,
    String? id,
    Map<String, dynamic>? metadata,
    PreviewData? previewData,
    String? remoteId,
    Message? repliedMessage,
    String? roomId,
    bool? showStatus,
    Status? status,
    String? text,
    int? updatedAt,
    PoliticalPosition? position,
  });

  /// Converts a text message to the map representation, encodable to JSON.
  @override
  Map<String, dynamic> toJson() => _$TextMessageToJson(this);
}

/// A utility class to enable better copyWith.
class _TextMessage extends TextMessage {
  const _TextMessage({
    required super.author,
    super.createdAt,
    required super.id,
    super.metadata,
    super.previewData,
    super.remoteId,
    super.repliedMessage,
    super.roomId,
    super.showStatus,
    super.status,
    required super.text,
    super.type,
    super.updatedAt,
    super.position,
  }) : super._();

  @override
  Message copyWith({
    User? author,
    dynamic createdAt = _Unset,
    String? id,
    dynamic metadata = _Unset,
    dynamic previewData = _Unset,
    dynamic remoteId = _Unset,
    dynamic repliedMessage = _Unset,
    dynamic roomId,
    dynamic showStatus = _Unset,
    dynamic status = _Unset,
    String? text,
    dynamic updatedAt = _Unset,
    dynamic position = _Unset,
  }) =>
      _TextMessage(
        author: author ?? this.author,
        createdAt: createdAt == _Unset ? this.createdAt : createdAt as int?,
        id: id ?? this.id,
        metadata: metadata == _Unset
            ? this.metadata
            : metadata as Map<String, dynamic>?,
        previewData: previewData == _Unset
            ? this.previewData
            : previewData as PreviewData?,
        remoteId: remoteId == _Unset ? this.remoteId : remoteId as String?,
        repliedMessage: repliedMessage == _Unset
            ? this.repliedMessage
            : repliedMessage as Message?,
        roomId: roomId ?? this.roomId,
        showStatus:
            showStatus == _Unset ? this.showStatus : showStatus as bool?,
        status: status == _Unset ? this.status : status as Status?,
        text: text ?? this.text,
        updatedAt: updatedAt == _Unset ? this.updatedAt : updatedAt as int?,
        position:
            position == _Unset ? this.position : position as PoliticalPosition?,
      );
}

class _Unset {}
