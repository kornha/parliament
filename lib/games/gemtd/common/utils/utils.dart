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

  // Compact display for stats that grow exponentially over the endless run
  // (enemy life/armor): 999.9 -> 1.0K -> 1.0M ... past quadrillions falls back
  // to scientific notation so the string stays short at any wave.
  static String compact(double n) {
    if (n < 0) return "-${compact(-n)}";
    const suffixes = ["", "K", "M", "B", "T", "Q"];
    var v = n;
    var i = 0;
    while (v >= 1000 && i < suffixes.length - 1) {
      v /= 1000;
      i++;
    }
    if (v >= 1000) return n.toStringAsExponential(1);
    return "${v.toStringAsFixed(1)}${suffixes[i]}";
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
