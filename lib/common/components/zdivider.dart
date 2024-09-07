import 'package:flutter/material.dart';
import 'package:political_think/common/extensions.dart';

enum DividerType { PRIMARY, SECONDARY, VERTICAL }

class ZDivider extends StatelessWidget {
  const ZDivider({
    super.key,
    this.type = DividerType.PRIMARY,
  });

  final DividerType type;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: type == DividerType.VERTICAL
          ? context.sd.width
          : context.blockSizeLarge.width,
      child: type == DividerType.VERTICAL
          ? VerticalDivider(
              color: context.surfaceColor,
              thickness: 1.0,
              indent: context.sh.height,
              endIndent: context.sh.height,
            )
          : Divider(
              color: type == DividerType.PRIMARY
                  ? context.surfaceColorBright
                  : context.surfaceColor,
              thickness: type == DividerType.PRIMARY ? 1.5 : 1.5,
            ),
    );
  }
}
