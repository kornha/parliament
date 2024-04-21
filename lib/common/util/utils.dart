import 'package:cloud_firestore/cloud_firestore.dart';

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
}
