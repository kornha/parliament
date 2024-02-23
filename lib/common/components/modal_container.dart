import 'package:flutter/material.dart';
import 'package:political_think/common/extensions.dart';

class ModalContainer extends StatelessWidget {
  const ModalContainer({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      color: context.backgroundColor,
      child: child,
    );
  }
}
