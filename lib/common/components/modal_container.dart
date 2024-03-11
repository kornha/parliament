import 'package:flutter/material.dart';
import 'package:political_think/common/extensions.dart';

class ModalContainer extends StatelessWidget {
  const ModalContainer({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.color,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      // HACK: Must be used with showCupertinoDialog (see below)
      // TODO: NEEDS TO BE TESTED ON OTHER PLATFORMS
      // I use a zscaffold with defaultSafeArea: false
      // This is because the top safe area does not calculate properly inside cupertino full screen dialog
      // however this has only been tested with ios
      top: false,
      child: Container(
        padding: padding,
        color: color ?? context.backgroundColor,
        child: child,
      ),
    );
  }
}
