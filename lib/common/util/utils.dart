import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;

class Utils {
  static Timestamp timestampFromJson(int milliseconds) =>
      Timestamp.fromMillisecondsSinceEpoch(milliseconds);

  static dynamic timestampToJson(Timestamp timestamp) =>
      timestamp.millisecondsSinceEpoch;

  static Timestamp? timestampFromJsonNullable(int? milliseconds) =>
      milliseconds == null
          ? null
          : Timestamp.fromMillisecondsSinceEpoch(milliseconds);

  static dynamic timestampToJsonNullable(Timestamp? timestamp) =>
      timestamp?.millisecondsSinceEpoch;

  static GeoPoint geoPointFromJson(GeoPoint geoPoint) => geoPoint;

  static GeoPoint geoPointToJson(GeoPoint geoPoint) => geoPoint;

  static String toHumanReadableDate(Timestamp? timestamp) {
    if (timestamp == null) {
      return "";
    }

    DateTime date =
        DateTime.fromMillisecondsSinceEpoch(timestamp.millisecondsSinceEpoch);

    // String pre = timestamp.millisecondsSinceEpoch <= Timestamp.now().millisecondsSinceEpoch
    //     ? ""
    //     : "in ";
    return timeago.format(date, locale: "en", allowFromNow: true);
  }

  static String numToReadableString(num? number) {
    if (number == null) {
      return "";
    }

    if (number >= 1000000) {
      // Format for millions
      return "${(number / 1000000).toStringAsFixed(1)}M";
    } else if (number >= 1000) {
      // Format for thousands
      return "${(number / 1000).toStringAsFixed(1)}K";
    } else {
      // Return the number as is if less than 1000
      return number.toString();
    }
  }

  static bool isURL(String? url) {
    if (url == null) {
      return false;
    }

    return url.startsWith("http://") ||
        url.startsWith("https://") ||
        url.startsWith("www.");
  }
}
