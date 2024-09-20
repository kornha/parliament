import 'package:flutter/material.dart';
import 'package:political_think/common/constants.dart';
import 'package:political_think/common/extensions.dart';

class Logo extends StatelessWidget {
  final double? size;

  const Logo({
    super.key,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    // TODO: Need to add sizing
    String path = context.isDarkMode
        ? 'assets/images/logo_white.png'
        : 'assets/images/logo_black.png';
    return Image.asset(
      path,
      fit: BoxFit.cover,
      width: size ?? context.iconSizeLarge,
      height: size ?? context.iconSizeLarge,
    );
  }
}

// TODO: Experimental, not final
class LogoName extends StatelessWidget {
  final double? size;

  const LogoName({
    super.key,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Logo(),
        context.sh,
        const LogoText(),
      ],
    );
  }
}

// TODO: Experimental, not final
class LogoText extends StatelessWidget {
  final double? size;

  const LogoText({
    super.key,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Text("Parliament", style: context.d3.copyWith(letterSpacing: 5));
  }
}
