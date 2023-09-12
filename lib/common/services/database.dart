import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:political_think/common/models/zuser.dart';

class Database {
  Database.instance();

  final CollectionReference userCollection =
      FirebaseFirestore.instance.collection('users');

  final userRef =
      FirebaseFirestore.instance.collection('users').withConverter<ZUser>(
            fromFirestore: (snapshots, _) => ZUser.fromJson(snapshots.data()!),
            toFirestore: (zuser, _) => zuser.toJson(),
          );

  final WriteBatch batch = FirebaseFirestore.instance.batch();

  Stream<ZUser?> getUser(uid) {
    return userRef.doc(uid).snapshots().map((event) => event.data());
  }

  Future updateUser(String uid, Map<String, Object?> data) async {
    return userCollection.doc(uid).update(data);
  }
}
