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
    return Padding(
      padding: context.blockPadding.copyWith(top: 0, bottom: 0),
      child: type == DividerType.VERTICAL
          ? VerticalDivider(
              color: context.surfaceColor,
              thickness: 1.0,
              indent: context.sh.height,
              endIndent: context.sh.height,
            )
          : Divider(
              color: type == DividerType.PRIMARY
                  ? context.primaryColor
                  : context.surfaceColor,
              thickness: type == DividerType.PRIMARY ? 7 : 2,
            ),
    );
  }
}
