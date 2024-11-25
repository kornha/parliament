import 'package:flutter/material.dart';
import 'package:political_think/common/extensions.dart';

class ModalContainer extends StatelessWidget {
  const ModalContainer({
    super.key,
    required this.child,
    this.color,
  });
  final Widget child;
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
        padding: context.blockPaddingExtra,
        // set min height
        constraints: BoxConstraints(
            minHeight: context.sqt.height!,
            maxWidth: context.blockSizeLarge.width),
        color: color ?? context.backgroundColor,
        // width: context.isDesktop ? context.blockSize.width : null,
        // height: context.isDesktop ? context.blockSize.height / 2 : null,
        child: child,
      ),
    );
  }
}
