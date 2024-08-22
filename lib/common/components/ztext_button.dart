import 'package:flutter/material.dart';
import 'package:political_think/common/constants.dart';
import 'package:political_think/common/extensions.dart';

enum ZButtonTypes { wide, standard, area, icon }

class ZTextButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color? foregroundColor;
  final Color? backgroundColor;
  final ZButtonTypes type;

  const ZTextButton({
    super.key,
    required this.child,
    this.foregroundColor,
    this.backgroundColor,
    this.onPressed,
    this.type = ZButtonTypes.standard,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: type == ZButtonTypes.area
            ? context.blockPadding
            : type == ZButtonTypes.wide
                ? context.blockPaddingSmall
                : type == ZButtonTypes.icon
                    ? EdgeInsets.zero
                    : const EdgeInsets.all(0.0),
        tapTargetSize:
            type == ZButtonTypes.icon ? MaterialTapTargetSize.shrinkWrap : null,
        shape: type == ZButtonTypes.area
            ? const RoundedRectangleBorder(
                borderRadius: BRadius.least,
              )
            : type == ZButtonTypes.icon
                ? const CircleBorder()
                : null,
        foregroundColor: foregroundColor ?? context.primaryColor,
        backgroundColor: backgroundColor != null && onPressed != null
            ? backgroundColor
            : Colors.transparent,
        minimumSize: type == ZButtonTypes.area
            ? null
            : type == ZButtonTypes.wide
                ? Size(context.blockSize.width, context.sd.height!)
                : type == ZButtonTypes.icon
                    ? const Size(0, 0)
                    : null,
      ),
      child: child,
    );
  }
}
