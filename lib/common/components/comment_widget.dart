import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:political_think/common/constants.dart';
import 'package:political_think/common/extensions.dart';
import 'package:political_think/common/models/political_position.dart';

class CommentWidget extends StatelessWidget {
  final int? comments;
  final double? size;
  final PoliticalPosition? position;
  const CommentWidget({
    super.key,
    this.comments,
    this.size,
    this.position,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size ?? context.iconSizeLarge,
      height: (size ?? context.iconSizeLarge),
      //padding: const EdgeInsets.all(Margins.quarter),
      decoration: const BoxDecoration(
          //borderRadius: BRadius.standard,
          // color: context.surfaceColor,
          //border: Border.all(color: context.secondaryColor, width: 1),
          ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            FontAwesomeIcons.handFist,
            size: size ?? context.iconSizeLarge,
            color: position?.color.withOpacity(0.25) ??
                context.primaryColorWithOpacity,
          ),
          Text(
            (comments ?? 0) > 999
                ? "${(comments ?? 0) ~/ 1000}K+"
                : (comments ?? 0).toString(),
            style: (size ?? 0) > IconSize.large
                // we dont use oncolor since opacity is used
                ? context.h3.copyWith(color: context.primaryColor)
                : context.l.copyWith(color: context.primaryColor),
          ),
        ],
      ),
    );
  }
}
