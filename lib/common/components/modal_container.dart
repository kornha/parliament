import 'package:flutter/material.dart';
import 'package:political_think/common/extensions.dart';

class ModalContainer extends StatelessWidget {
  const ModalContainer({
    super.key,
    required this.child,
  });
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.surfaceColor,
      child: child,
    );
  }
}
