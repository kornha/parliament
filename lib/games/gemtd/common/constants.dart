import 'package:flutter/material.dart';

class Constants {
  static const String LoadingIndicatorType = 'LOADING';
  static const String SortString = 'SORT';
  static const String GroupString = 'GROUP';
  static const String Preview = 'PREVIEW';

  static const int ItemRequestThreshold = 25;
  static const double BarHeight = 66;
  static const double standardBorderWidth = 3.0;
  static const double boldBorderWidth = 5.0;

  static const double textButtonWidth = 66;
  static const double textButtonHeight = 46;
  static const double smallButtonWidth = 46;
  static const double smallButtonHeight = 36;

  static const GAME_PRIORITY = 10;
  static const ROCK_PRIORITY = 20;
  static const AURA_PRIORITY = 30;
  static const CITY_PRIORITY = 40;
  static const ENEMY_PRIORITY = CITY_PRIORITY;
  static const NEUTRAL_PRIORITY = CITY_PRIORITY;

  static const PROJECTILE_PRIORITY = 50;
  static const EXPLOSION_PRIORITY = 60;

  static const STATS_PRIORITY = 90;
}

class ThemeConstants {
  static final darkTheme = ThemeData(
    highlightColor: Colors.transparent,
    splashColor: Colors.transparent,
    hoverColor: Colors.transparent,
    primaryColor: Palette.white,
    unselectedWidgetColor: Palette.darkSlate,
    textTheme: const TextTheme()
        .apply(bodyColor: Palette.white, displayColor: Palette.white),
    brightness: Brightness.dark,
  );

  static final lightTheme = ThemeData(
    highlightColor: Colors.transparent,
    splashColor: Colors.transparent,
    hoverColor: Colors.transparent,
    primaryColor: Palette.white,
    unselectedWidgetColor: Palette.lightSlate,
    textTheme: const TextTheme()
        .apply(bodyColor: Palette.black, displayColor: Palette.black),
    brightness: Brightness.light,
  );
}

class Durations {
  static const Duration transitionDuration = Duration(milliseconds: 200);
}

class Margins {
  static const double least = full / 8;
  static const double quarter = full / 4;
  static const double half = full / 2;
  static const double full = 32.0;
  static const double threeHalf = full * 1.5;
  static const double twice = full * 2;
  static const double triple = full * 3;
  static const double quadruple = full * 4;
  static const double quintuple = full * 5;
}

class Curvature {
  static const Radius none = Radius.circular(0.0);
  static const Radius least = Radius.circular(2.0);
  static const Radius little = Radius.circular(4.0);
  static const Radius standard = Radius.circular(8.0);
  static const Radius steep = Radius.circular(32.0);
}

class BRadius {
  static const none = BorderRadius.all(Curvature.none);
  static const least = BorderRadius.all(Curvature.least);
  static const little = BorderRadius.all(Curvature.little);
  static const standard = BorderRadius.all(Curvature.standard);
  static const steep = BorderRadius.all(Curvature.steep);
}

class Decorations {
  static var boxDecoration = BoxDecoration(
    borderRadius: BRadius.least,
    border: Border.all(color: Palette.white, width: 1),
  );
}

class IconSize {
  static const double small = 12.5;
  static const double standard = 25.0;
  static const double big = 33;
}

class Block {
  static const double blockWidthSmall = 600.0;
  static const double blockWidthLarge = 1000.0;
}

class UIHelpers {
  static const SizedBox verticalHalf = SizedBox(height: Margins.half);
  static const SizedBox verticalFull = SizedBox(height: Margins.full);
  static const SizedBox verticalTwice = SizedBox(height: Margins.twice);

  static const SizedBox horizontalHalf = SizedBox(width: Margins.half);
  static const SizedBox horizontalFull = SizedBox(width: Margins.full);
  static const SizedBox horizontalTwice = SizedBox(width: Margins.twice);

  static const SizedBox half =
      SizedBox(height: Margins.half, width: Margins.half);
  static const SizedBox full =
      SizedBox(height: Margins.full, width: Margins.full);
  static const SizedBox twice =
      SizedBox(height: Margins.twice, width: Margins.twice);
}

class Thickness {
  static const double least = 0.25;
  static const double small = 1.0;
  static const double normal = 2.0;
  static const double full = 4.0;
}

class ImageSize {
  static const double barButton = 20.0;
}

class DotsSize {
  static const double large = 200;
}

class Palette {
  static const black = Color.fromRGBO(0, 0, 0, 1);
  static const white = Color.fromRGBO(255, 255, 255, 1);

  //Accent Colors - whiteTransluscent paired with light mode and visa versa
  static const whiteTransluscent = Color.fromARGB(189, 255, 255, 255);
  static const blackTransluscent = Color.fromARGB(194, 0, 0, 0);

  //Accent Colors - lightSlate paired with light mode and visa versa
  static const lightSlate = Color.fromARGB(255, 116, 116, 116);
  static const darkSlate = Color.fromARGB(255, 57, 57, 57);

  static const whiteGradient = LinearGradient(colors: [white, Colors.white30]);
  static const blackGradient = LinearGradient(colors: [black, Colors.black38]);

  static const orange = Color.fromARGB(255, 242, 83, 15);
  static const darkGreen = Color.fromARGB(255, 2, 58, 1);
  static const navy = Color.fromARGB(255, 2, 7, 67);
  static const yellow = Color.fromARGB(255, 234, 255, 0);
  static const green = Color.fromARGB(255, 60, 255, 0);
  //
  static const nAmericaNavy = Color.fromARGB(255, 10, 49, 97);
  static const nAmericaRed = Color.fromARGB(255, 179, 25, 66);
  static const eAsiaRed = Color.fromARGB(255, 219, 56, 50);
  static const aseanBlue = Color.fromARGB(255, 20, 54, 155);
  static const aseanRed = Color.fromARGB(255, 213, 75, 61);
  static const menaGreen = Color.fromARGB(255, 22, 93, 49);
  static const ukNavy = Color.fromARGB(255, 1, 33, 105);
  static const ukRed = Color.fromARGB(255, 200, 16, 46);
}

class TextConstants {
  // Parliament fonts: Avenir for body text (was GoogleFonts.montserrat/roboto),
  // Minecart for display text (was the "Hackney" custom font).
  static const TextStyle gem = TextStyle(
    fontFamily: "Avenir",
    fontSize: 20,
    color: Colors.white,
    shadows: [
      Shadow(
        color: Color(0x40000000),
        offset: Offset(1, 1),
        blurRadius: 4,
      )
    ],
    fontWeight: FontWeight.normal,
  );

  static const TextStyle gemSmall = TextStyle(
    fontFamily: "Avenir",
    fontSize: 7,
    color: Colors.white,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle hackney = TextStyle(
    fontSize: 35,
    color: Colors.red,
    fontWeight: FontWeight.bold,
    fontFamily: "Minecart",
  );

  static const TextStyle hackneySmall = TextStyle(
    fontSize: 18,
    color: Colors.white,
    fontWeight: FontWeight.bold,
    fontFamily: "Minecart",
  );

  // TextStyle get w1 => TextStyle(
  //     fontSize: isMobile
  //         ? 55
  //         : isTablet
  //             ? 75
  //             : 100,
  //     color: foregroundColor,
  //     fontFamily: "Hackney");

  // TextStyle get w2 => TextStyle(
  //     fontSize: isMobile
  //         ? 42
  //         : isTablet
  //             ? 46
  //             : 50,
  //     color: foregroundColor,
  //     fontFamily: "Hackney");
}

class gScrollView extends StatelessWidget {
  const gScrollView({
    super.key,
    required this.child,
    this.scrollDirection = Axis.vertical,
  });
  final Widget child;
  final Axis scrollDirection;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      scrollDirection: scrollDirection,
      child: child,
    );
  }
}
