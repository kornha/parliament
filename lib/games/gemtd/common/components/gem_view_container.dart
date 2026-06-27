import 'package:flutter/material.dart';
import 'package:political_think/games/gemtd/common/constants.dart';
import 'package:political_think/games/gemtd/common/extensions.dart';

class GemViewContainer extends StatelessWidget {
  const GemViewContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
  });
  final Widget child;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: context.ph.copyWith(bottom: context.sf.height),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Palette.white,
            width: 0.2,
          ),
        ),
        color: Palette.black,
      ),
      child: child,
    );
  }
}
