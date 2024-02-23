import 'package:flutter/material.dart';
import 'package:political_think/common/constants.dart';
import 'package:political_think/common/extensions.dart';

enum ZButtonTypes { wide, standard, area }

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
        shape: type == ZButtonTypes.area
            ? const RoundedRectangleBorder(
                borderRadius: BRadius.least,
              )
            : null,
        foregroundColor: foregroundColor ?? context.primaryColor,
        backgroundColor: backgroundColor ?? Colors.transparent,
        minimumSize: type == ZButtonTypes.area
            ? null
            : type == ZButtonTypes.wide
                ? Size(context.blockSizeSmall.width, context.sd.height!)
                : null,
      ),
      child: Padding(
        padding: type == ZButtonTypes.area
            ? context.blockPadding
            : type == ZButtonTypes.wide
                ? context.blockPaddingSmall
                : const EdgeInsets.all(0.0),
        child: child,
      ),
    );
  }
}
