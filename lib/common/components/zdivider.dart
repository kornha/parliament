import 'package:flutter/material.dart';
import 'package:political_think/common/constants.dart';
import 'package:political_think/common/extensions.dart';

enum DividerType { PRIMARY, SECONDARY, TERTIARY, VERTICAL, VERTICAL_SECONDARY }

class ZDivider extends StatelessWidget {
  const ZDivider({
    super.key,
    this.type = DividerType.PRIMARY,
  });

  final DividerType type;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: type == DividerType.TERTIARY
          ? context.blockSizeLarge.width / 2
          : type == DividerType.VERTICAL ||
                  type == DividerType.VERTICAL_SECONDARY
              ? context.sd.width
              : context.blockSizeLarge.width,
      child: type == DividerType.VERTICAL ||
              type == DividerType.VERTICAL_SECONDARY
          ? VerticalDivider(
              color: context.surfaceColor,
              thickness: Thickness.small,
              indent: type == DividerType.VERTICAL ? context.sh.height! : 0,
              endIndent: type == DividerType.VERTICAL ? context.sh.height! : 0,
            )
          : Divider(
              color: type == DividerType.PRIMARY
                  ? context.surfaceColorBright
                  : context.surfaceColor,
              thickness: Thickness.standard,
            ),
    );
  }
}
