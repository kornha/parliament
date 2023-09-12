import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:political_think/common/models/zuser.dart';
import 'package:political_think/common/services/auth.dart';

final firebaseAuthProvider =
    Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

final authProvider = ChangeNotifierProvider<AuthState>((ref) {
  return AuthState.instance();
});

final zuserProvider = StreamProvider.family<ZUser?, String>((ref, uid) {
  final zuserRef = FirebaseFirestore.instance.collection('Users').doc(uid);
  return zuserRef.snapshots().map((snapshot) {
    if (snapshot.exists) {
      final data = snapshot.data() as Map<String, dynamic>;
      return ZUser.fromJson(data);
    } else {
      return null;
    }
  });
});

// final zuserProvider = ChangeNotifierProvider.family<ZUser, String>((ref, uid) {
//   return ZUser(uid: uid);
// });

// register others providers

// final firebaseFirestoreProvider =
//     Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

// final firebaseStorageProvider =
//     Provider<FirebaseStorage>((ref) => FirebaseStorage.instance);

extension ProviderExt on WidgetRef {
  get authWatch => watch(authProvider);
  get authRead => read(authProvider);
  userWatch(uid) => watch(zuserProvider(uid));
  userRead(uid) => read(zuserProvider(uid));
}

extension ThemeExt on BuildContext {
  Color get primaryColor => Theme.of(this).primaryColor;
}
