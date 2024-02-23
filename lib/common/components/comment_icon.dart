import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:political_think/common/constants.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/models/political_position.dart';

class CommentIcon extends StatelessWidget {
  final int? comments;
  final double? size;
  final PoliticalPosition? position;
  const CommentIcon({
    super.key,
    this.comments,
    this.size,
    this.position,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size ?? context.iconSizeXL,
      height: (size ?? context.iconSizeXL),
      //padding: const EdgeInsets.all(Margins.quarter),
      decoration: const BoxDecoration(
          //borderRadius: BRadius.standard,
          // color: context.surfaceColor,
          //border: Border.all(color: context.secondaryColor, width: 1),
          ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            (comments ?? 0) > 999
                ? "${(comments ?? 0) ~/ 1000}K+"
                : (comments ?? 0).toString(),
            style: context.h3.copyWith(color: context.primaryColor),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                FontAwesomeIcons.circleDot,
                color: position == null
                    ? context.secondaryColor.withOpacity(0.5)
                    : position?.quadrant.color,
                size: size ?? context.iconSizeSmall,
              ),
              context.sl,
              Text(
                position?.quadrant.name ?? "n/a",
                style: context.sb.copyWith(
                  color: position == null
                      ? context.secondaryColor.withOpacity(0.5)
                      : position?.quadrant.color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
