import 'package:flutter/material.dart';
import 'package:political_think/common/constants.dart';
import 'package:political_think/common/extensions.dart';

import '../state/inherited_chat_theme.dart';
import '../state/inherited_l10n.dart';

/// A class that represents send button widget.
class SendButton extends StatelessWidget {
  /// Creates send button widget.
  const SendButton({
    super.key,
    required this.onPressed,
    this.padding = EdgeInsets.zero,
  });

  /// Callback for send button tap event.
  final VoidCallback onPressed;

  /// Padding around the button.
  final EdgeInsets padding;

  // : TODO: Hacky, splash not working right in light mode
  @override
  Widget build(BuildContext context) => Container(
        margin: InheritedChatTheme.of(context).theme.sendButtonMargin ??
            const EdgeInsetsDirectional.fromSTEB(0, 0, 8, 0),
        child: IconButton(
          splashColor: context.primaryColor,
          iconSize: IconSize.small,
          icon: InheritedChatTheme.of(context).theme.sendButtonIcon!,
          onPressed: onPressed,
          // padding: padding,
          // tooltip: InheritedL10n.of(context).l10n.sendButtonAccessibilityLabel,
        ),
      );
}
