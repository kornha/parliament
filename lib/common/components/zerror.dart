import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:political_think/common/extensions.dart';

class ZError extends StatelessWidget {
  const ZError({
    Key? key,
    this.size = 55.0,
  }) : super(key: key);

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: Icon(
          FontAwesomeIcons.circleExclamation,
          size: size,
          color: context.errorColor,
        ),
      ),
    );
  }
}
