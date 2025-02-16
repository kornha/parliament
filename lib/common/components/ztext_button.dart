import 'package:flutter/material.dart';
import 'package:political_think/common/constants.dart';
import 'package:political_think/common/extensions.dart';

enum ZButtonTypes { wide, standard, area, icon, iconSpace }

class ZTextButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color? foregroundColor;
  final Color? backgroundColor;
  final ZButtonTypes type;
  final Size? minimumSize;

  const ZTextButton({
    super.key,
    required this.child,
    this.foregroundColor,
    this.backgroundColor,
    this.minimumSize,
    this.onPressed,
    this.type = ZButtonTypes.standard,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: onPressed == null,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          // alignment: ZButtonTypes.iconSpace == type
          //     ? Alignment.bottomCenter
          //     : Alignment.center,
          padding: type == ZButtonTypes.area
              ? const EdgeInsets.all(0.0)
              : type == ZButtonTypes.wide
                  ? context.blockPaddingSmall
                  : type == ZButtonTypes.icon || type == ZButtonTypes.iconSpace
                      ? EdgeInsets.zero
                      : const EdgeInsets.all(0.0),
          tapTargetSize:
              type == ZButtonTypes.icon || type == ZButtonTypes.iconSpace
                  ? MaterialTapTargetSize.shrinkWrap
                  : null,
          shape: type == ZButtonTypes.area || type == ZButtonTypes.iconSpace
              ? const RoundedRectangleBorder(
                  borderRadius: BRadius.least,
                )
              : type == ZButtonTypes.icon
                  ? const CircleBorder()
                  : null,
          foregroundColor: foregroundColor ?? context.primaryColor,
          backgroundColor: type == ZButtonTypes.iconSpace
              ? Colors.transparent
              : backgroundColor != null && onPressed != null
                  ? backgroundColor
                  : Colors.transparent,
          minimumSize: minimumSize ??
              (type == ZButtonTypes.area
                  ? null
                  : type == ZButtonTypes.wide
                      ? Size(context.blockSize.width, context.sfh.height!)
                      : type == ZButtonTypes.icon
                          ? Size(context.iconSizeLarge, context.iconSizeLarge)
                          : type == ZButtonTypes.iconSpace
                              ? Size(
                                  context.isDesktop
                                      ? context.sfh.width!
                                      : context.sqd.width!,
                                  double.infinity)
                              : null),
        ),
        child: child,
      ),
    );
  }
}
