import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class Constants {
  static const MESSAGE_FETCH_LIMIT = 50;
}

class Palette {
  static const black = Color.fromRGBO(0, 0, 0, 1);
  static const white = Color.fromRGBO(255, 255, 255, 1);

  static const lightSlate = Color.fromARGB(255, 116, 116, 116);
  static const darkSlate = Color.fromARGB(255, 28, 28, 30);

  static const red = Color.fromRGBO(255, 0, 0, 1);
  static const green = Color.fromRGBO(0, 255, 0, 1);
  static const blue = Color.fromRGBO(0, 0, 255, 1);
  static const purple = Color.fromRGBO(255, 0, 255, 1);
  static const orange = Color.fromRGBO(255, 85, 0, 1);
  static const teal = Color.fromRGBO(0, 255, 255, 1);
}

class Durations {
  static const Duration transitionDuration = Duration(milliseconds: 200);
}

class Margins {
  static const double least = full / 8;
  static const double quarter = full / 4;
  static const double half = full / 2;
  static const double threeQuarter = 3 * full / 4;
  static const double full = 16.0;
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
  static const Radius circular = Radius.circular(64.0);
}

class BRadius {
  static const none = BorderRadius.all(Curvature.none);
  static const least = BorderRadius.all(Curvature.least);
  static const little = BorderRadius.all(Curvature.little);
  static const standard = BorderRadius.all(Curvature.standard);
  static const steep = BorderRadius.all(Curvature.steep);
  static const circular = BorderRadius.all(Curvature.circular);
}

// Should be moved to context
class IconSize {
  static const double small = 12.5;
  static const double standard = 24.0;
  static const double large = 33;
  static const double xl = 50;
  static const double xxl = 75;
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
