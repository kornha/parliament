import 'package:flutter/material.dart';
import 'package:political_think/common/constants.dart';
import 'package:political_think/common/extensions.dart';

class ZTextButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color? foregroundColor;
  final Color? backgroundColor;

  const ZTextButton({
    super.key,
    required this.child,
    this.foregroundColor,
    this.backgroundColor,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: foregroundColor ?? context.onSurfaceColor,
        backgroundColor: backgroundColor ?? context.backgroundColor,
        padding: context.blockPadding.copyWith(top: 0, bottom: 0),
      ),
      child: Container(
        constraints: const BoxConstraints(
          minWidth: Margins.quintuple,
        ),
        child: Center(child: child),
      ),
    );
  }
}
