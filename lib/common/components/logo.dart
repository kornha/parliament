import 'package:flutter/material.dart';
import 'package:political_think/common/constants.dart';
import 'package:political_think/common/extensions.dart';

class Logo extends StatelessWidget {
  final double? size;
  final bool? isDarkMode;

  const Logo({
    super.key,
    this.size,
    this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    // TODO: Need to add sizing
    String path = isDarkMode ?? context.isDarkMode
        ? 'assets/images/logo_white.png'
        : 'assets/images/logo_black.png';
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          context.route("/");
        },
        child: Image.asset(
          path,
          fit: BoxFit.contain,
          width: size ?? context.iconSizeLarge,
          height: size ?? context.iconSizeLarge,
        ),
      ),
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
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          context.route("/");
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Logo(),
            context.sh,
            const LogoText(),
          ],
        ),
      ),
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
    return Text("Parliament", style: context.h1.copyWith(letterSpacing: 5));
  }
}
