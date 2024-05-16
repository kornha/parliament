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

  static String toHumanReadableDate(Timestamp? timestamp) {
    if (timestamp == null) {
      return "";
    }
    DateTime date =
        DateTime.fromMillisecondsSinceEpoch(timestamp.millisecondsSinceEpoch);
    return timeago.format(date, locale: "en_short");
  }
}
