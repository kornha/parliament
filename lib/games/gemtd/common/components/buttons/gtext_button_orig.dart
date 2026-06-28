// import 'package:flutter/src/widgets/container.dart';
// import 'package:flutter/src/widgets/framework.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:political_think/games/gemtd/common/constants.dart';
//
// class GTextButton extends StatelessWidget {
//   final IconData icon;
//   final bool isActive;
//   final void Function()? onPressed;
//   final Color color;
//   final Color iconColor;
//
//   final bool small;
//
//   const GTextButton({
//     super.key,
//     required this.icon,
//     this.onPressed,
//     this.isActive = true,
//     required this.color,
//     this.iconColor = Colors.white,
//     this.small = false,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     var onPress = isActive ? onPressed : null;
//     return Neumorphic(
//       style: NeumorphicStyle(
//         depth: 0.33,
//         boxShape: NeumorphicBoxShape.roundRect(BRadius.least),
//       ),
//       child: Container(
//         width: small ? Constants.smallButtonWidth : Constants.textButtonWidth,
//         height:
//             small ? Constants.smallButtonHeight : Constants.textButtonHeight,
//         decoration: BoxDecoration(
//           color: color,
//           borderRadius: BRadius.least,
//         ),
//         child: TextButton(
//           onPressed: onPress,
//           child: Icon(
//             icon,
//             color: iconColor,
//             size: 20,
//             // color: widget.isActive ? Colors.white : Colors.grey,
//           ),
//         ),
//       ),
//     );
//   }
// }
