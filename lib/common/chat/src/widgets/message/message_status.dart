import 'package:flutter/material.dart';
import 'package:political_think/common/chat/chat_types/flutter_chat_types.dart'
    as types;
import 'package:political_think/common/components/loading.dart';
import 'package:political_think/common/components/zerror.dart';
import 'package:political_think/common/constants.dart';
import 'package:political_think/common/extensions.dart';
import '../state/inherited_chat_theme.dart';

/// A class that represents a message status.
class MessageStatus extends StatelessWidget {
  /// Creates a message status widget.
  const MessageStatus({
    super.key,
    required this.status,
  });
  // added this as only want to show loading or errored
  // otherwise we show icon which done directly in the message widget
  static bool shouldShowMessageStatus(types.Status? status) {
    return status == types.Status.sending || status == types.Status.error;
  }

  /// Status of the message.
  final types.Status? status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case types.Status.delivered:
      case types.Status.sent:
        return InheritedChatTheme.of(context).theme.deliveredIcon!;
      case types.Status.error:
        return const ZError(size: IconSize.small);
      case types.Status.seen:
        return InheritedChatTheme.of(context).theme.seenIcon != null
            ? InheritedChatTheme.of(context).theme.seenIcon!
            : Image.asset(
                'assets/icon-seen.png',
                color: InheritedChatTheme.of(context).theme.primaryColor,
                package: 'flutter_chat_ui',
              );
      case types.Status.sending:
        return const Loading(type: LoadingType.small);
      default:
        return const SizedBox(width: 8);
    }
  }
}
