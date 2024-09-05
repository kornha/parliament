import 'package:flutter/material.dart';
import 'package:political_think/common/extensions.dart';

class ZIconText extends StatelessWidget {
  final IconData icon;
  final String text;
  const ZIconText({
    super.key,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: context.iconSizeSmall, color: context.secondaryColor),
        context.sq,
        Text(text, style: context.m.copyWith(color: context.secondaryColor)),
      ],
    );
  }
}
