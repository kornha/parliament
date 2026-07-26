import 'package:flutter/material.dart';
import 'package:political_think/games/gemtd/common/constants.dart';
import 'package:political_think/games/gemtd/common/extensions.dart';

// Flat action button matching the app's terminal style: thin hairline border,
// small radius, no shadows. The fill color carries the action's meaning
// (destroy/confirm/upgrade/special).
class GTextButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final void Function()? onPressed;
  final Color color;
  final Color iconColor;

  final bool small;

  const GTextButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.isActive = true,
    required this.color,
    this.iconColor = Colors.white,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final onPress = isActive ? onPressed : null;
    return Opacity(
      opacity: isActive ? 1.0 : 0.4,
      child: Material(
        color: color,
        borderRadius: BRadius.least,
        child: InkWell(
          borderRadius: BRadius.least,
          onTap: onPress,
          child: Container(
            width:
                small ? Constants.smallButtonWidth : Constants.textButtonWidth,
            height: small
                ? Constants.smallButtonHeight
                : Constants.textButtonHeight,
            decoration: BoxDecoration(
              borderRadius: BRadius.least,
              border: Border.all(
                color: context.foregroundColorTansluscent,
                width: 0.5,
              ),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
