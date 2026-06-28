import 'package:flutter/material.dart';
import 'package:political_think/games/gemtd/common/constants.dart';
import 'package:neumorphic_button/neumorphic_button.dart';

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
    var onPress = isActive ? onPressed : null;
    return NeumorphicButton(
      //TODO adjust shadow colors
      topLeftShadowColor: Colors.grey.shade900,
      bottomRightShadowColor: Colors.grey.shade800,
      borderRadius: Curvature.least.x,
      width: small ? Constants.smallButtonWidth : Constants.textButtonWidth,
      height: small ? Constants.smallButtonHeight : Constants.textButtonHeight,
      padding: EdgeInsets.zero,
      margin: EdgeInsets.zero,
      backgroundColor: color,
      onTap: onPress ?? () {},
      child: Icon(
        icon,
        color: iconColor,
        size: 20,
      ),
    );
  }
}
