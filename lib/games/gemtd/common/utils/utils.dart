import 'dart:math';

import 'package:flag/flag.dart';

class Utils {
  static String getFormattedCapital(double capital) {
    if (capital < 100) {
      return "${capital.toStringAsFixed(2)}M";
    } else if (capital < 1000) {
      return "${capital.toStringAsFixed(1)}M";
    }
    capital = capital / 1000.0;
    if (capital < 100) {
      return "${capital.toStringAsFixed(2)}B";
    } else {
      return "${capital.toStringAsFixed(1)}B";
    }
  }

  static double toDoubleCelWithPrecision(double value, int places) {
    num mod = pow(10.0, places);
    return ((value * mod).ceil().toDouble() / mod);
  }

  static Flag gFlag(String code, {double width = 20, double height = 15}) {
    return Flag.fromString(
      code,
      width: width,
      height: height,
      flagSize: FlagSize.size_4x3,
    );
  }
}
