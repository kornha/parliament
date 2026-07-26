import 'package:flutter/material.dart';
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
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: context.foregroundColorTansluscent,
            width: 0.5,
          ),
        ),
        color: context.backgroundColor,
      ),
      child: child,
    );
  }
}
