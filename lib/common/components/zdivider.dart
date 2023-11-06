import 'package:flutter/material.dart';
import 'package:political_think/common/extensions.dart';

enum DividerType { PRIMARY, SECONDARY }

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
      child: Divider(
        color: context.primaryColor,
        thickness: type == DividerType.PRIMARY ? 7 : 2,
      ),
    );
  }
}
