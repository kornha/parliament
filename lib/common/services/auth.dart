import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:political_think/firebase_options.dart';

enum AuthStatus { authenticating, authenticated, unauthenticated, unknown }

class AuthState extends ChangeNotifier {
  AuthStatus status = AuthStatus.unknown;
  final Auth _auth = Auth();
  User? authUser;

  bool get isLoggedIn => status == AuthStatus.authenticated;
  bool get isLoading =>
      status == AuthStatus.unknown || status == AuthStatus.authenticating;

  AuthState.instance() {
    status = AuthStatus.unknown;
    _auth.auth.authStateChanges().listen((user) async {
      authUser = user;
      if (user == null) {
        status = AuthStatus.unauthenticated;
      } else {
        status = AuthStatus.authenticated;
      }
      notifyListeners();
    });
  }
}

class Auth {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _googleSignIn = GoogleSignIn(
    scopes: ["email"],
    clientId: DefaultFirebaseOptions.currentPlatform.iosClientId,
    hostedDomain: DefaultFirebaseOptions.currentPlatform.authDomain,
  );

  Stream<User?> get fbUser {
    return _auth.authStateChanges();
  }

  FirebaseAuth get auth => _auth;
  bool get isLoggedIn => _auth.currentUser != null;

  /* Google */
  Future<UserCredential> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    GoogleSignInAuthentication? googleAuth;
    try {
      googleAuth = await googleUser!.authentication;
    } catch (e) {
      //TODO: Toast?
      print(e);
    }

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  Future signOut() async {
    try {
      return await _auth.signOut();
    } catch (error) {
      // TODO toast
      print(error.toString());
      return null;
    }
  }

  Future resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<User?> firebaseUser() async {
    var user = _auth.currentUser;
    await user?.reload();
    return user;
  }
}
