import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:political_think/common/extensions.dart';

enum ErrorType { profile, standard, large, imageSmall, image, post }

class ZError extends StatelessWidget {
  final ErrorType type;
  const ZError({
    Key? key,
    this.size = 55.0,
    this.type = ErrorType.large,
  }) : super(key: key);

  final double size;

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case ErrorType.image:
        return Container(
          width: context.imageSize.width,
          height: context.imageSize.height,
          decoration: BoxDecoration(
            border: Border.all(color: context.surfaceColor, width: 1),
          ),
          child: Center(
            child: Icon(
              FontAwesomeIcons.faceAngry,
              color: context.errorColor,
              size: context.iconSizeLarge,
            ),
          ),
        );

      case ErrorType.imageSmall:
        return Container(
          width: context.imageSizeSmall.width,
          height: context.imageSizeSmall.height,
          decoration: BoxDecoration(
            border: Border.all(color: context.surfaceColor, width: 1),
          ),
          child: Center(
            child: Icon(
              FontAwesomeIcons.faceAngry,
              color: context.errorColor,
              size: context.iconSizeProfile,
            ),
          ),
        );

      default:
        return Icon(
          FontAwesomeIcons.faceAngry,
          color: context.errorColor,
          size: type == ErrorType.profile
              ? context.iconSizeProfile
              : context.iconSizeLarge,
        );
    }
  }
}
