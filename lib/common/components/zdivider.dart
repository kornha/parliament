import 'package:flutter/material.dart';
import 'package:political_think/common/constants.dart';
import 'package:political_think/common/extensions.dart';

enum DividerType { PRIMARY, SECONDARY, TERTIARY, VERTICAL, VERTICAL_SECONDARY }

class ZDivider extends StatelessWidget {
  const ZDivider({
    super.key,
    this.type = DividerType.PRIMARY,
    this.text,
  });

  /// Add a [text] to display on top of the divider (only displayed if
  /// [type] is [PRIMARY] or [SECONDARY] for horizontal dividers).
  final String? text;
  final DividerType type;

  @override
  Widget build(BuildContext context) {
    // Handle vertical dividers first (unchanged).
    if (type == DividerType.VERTICAL ||
        type == DividerType.VERTICAL_SECONDARY) {
      return SizedBox(
        width: context.sd.width,
        child: VerticalDivider(
          color: context.surfaceColor,
          thickness: Thickness.small,
          indent: type == DividerType.VERTICAL ? context.sh.height! : 0,
          endIndent: type == DividerType.VERTICAL ? context.sh.height! : 0,
        ),
      );
    }

    // Handle horizontal tertiary divider (unchanged).
    if (type == DividerType.TERTIARY) {
      return SizedBox(
        width: context.blockSizeLarge.width / 2,
        child: Divider(
          color: context.surfaceColor, // or context.surfaceColor
          thickness: Thickness.standard,
        ),
      );
    }

    // For PRIMARY or SECONDARY horizontal dividers, we will optionally
    // show the [text] on top of the divider (on the left side).
    return SizedBox(
      width: context.blockSizeLarge.width,
      child: text != null && text!.isNotEmpty
          ? Stack(
              alignment: Alignment.centerLeft,
              children: [
                // The Divider itself in the background
                Divider(
                  color: type == DividerType.PRIMARY
                      ? context.primaryColor
                      : context.surfaceColor,
                  thickness: type == DividerType.PRIMARY
                      ? Thickness.large
                      : Thickness.standard,
                ),
                // Text on top, aligned left, with a background to "cover" the divider
                Container(
                  color: context.backgroundColor,
                  child: Text(
                    text!,
                    style: context.sb.copyWith(color: context.secondaryColor),
                  ),
                ),
              ],
            )
          : Divider(
              color: type == DividerType.PRIMARY
                  ? context.primaryColor
                  : context.surfaceColor,
              thickness: type == DividerType.PRIMARY
                  ? Thickness.large
                  : Thickness.standard,
            ),
    );
  }
}
