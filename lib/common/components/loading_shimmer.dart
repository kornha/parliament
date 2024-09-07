import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:political_think/common/extensions.dart';
import 'package:shimmer/shimmer.dart';

class LoadingShimmer extends StatelessWidget {
  final Widget child;
  final Color? color;

  const LoadingShimmer({
    super.key,
    required this.child,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Shimmer(
          period: const Duration(milliseconds: 3000),
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color ?? context.surfaceColor,
                color?.withAlpha(100) ?? context.surfaceColor.withAlpha(100),
                color ?? context.surfaceColor,
              ],
              stops: const <double>[
                0.3,
                0.5,
                0.2,
              ]),
          child: child,
        ),
      ],
    );
  }
}
