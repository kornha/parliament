import 'package:flutter/material.dart';
import 'package:political_think/common/constants.dart';
import 'package:political_think/common/extensions.dart';

/// A score widget (confidence dot-matrix, bias globe, virality wave...) with
/// a tiny dot-matrix label beneath it, so the raw numbers read as *something*
/// at a glance ("news", "bias", "trust"). [dim] renders the whole cluster
/// faded — used for unmeasured values (e.g. unverified claims).
class LabeledScore extends StatelessWidget {
  const LabeledScore({
    super.key,
    required this.child,
    required this.label,
    this.dim = false,
  });

  final Widget child;
  final String label;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: dim ? 0.45 : 1.0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          child,
          const SizedBox(height: Margins.least),
          Text(
            label,
            style: context.as.copyWith(color: Palette.lightSlate),
          ),
        ],
      ),
    );
  }
}
