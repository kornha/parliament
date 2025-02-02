import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:political_think/firebase_options.dart';

enum AuthStatus { authenticating, authenticated, unauthenticated, unknown }

enum Role { admin, user, unknown }

class Auth extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AuthStatus status = AuthStatus.unknown;
  Role roll = Role.unknown;
  User? authUser;

  bool get isLoggedOut => status == AuthStatus.unauthenticated;
  bool get isLoggedIn => status == AuthStatus.authenticated;
  bool get isLoading =>
      status == AuthStatus.unknown || status == AuthStatus.authenticating;
  bool get isUnknown => status == AuthStatus.unknown;
  bool get isAdmin => roll == Role.admin;

  // Add a private static instance variable
  static final Auth _instance = Auth._internal();

  // Private constructor
  Auth._internal() {
    status = AuthStatus.unknown;
    _auth.authStateChanges().listen((user) async {
      User? previousUser = authUser;
      authUser = user;
      if (user == null) {
        status = AuthStatus.unauthenticated;
        roll = Role.unknown;
      } else {
        status = AuthStatus.authenticated;
      }

      if (previousUser?.uid != authUser?.uid && authUser != null) {
        // add 3 second delay
        var claims = await _getCustomClaims();
        if (claims != null) {
          roll = claims["role"] == Role.admin.name ? Role.admin : Role.user;
        }
      }
      notifyListeners();
    });
  }

  // Factory constructor that returns the same instance
  factory Auth.instance() => _instance;

  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      // Create a new provider
      GoogleAuthProvider googleProvider = GoogleAuthProvider();

      googleProvider.addScope("email");
      googleProvider.setCustomParameters({'login_hint': 'user@example.com'});

      return await FirebaseAuth.instance.signInWithPopup(googleProvider);

      // FirebaseAuth.instance.signInWithRedirect(googleProvider);
      // After the page redirects back
      // return await FirebaseAuth.instance.getRedirectResult();
    } else {
      final googleSignIn = GoogleSignIn(
        scopes: ["email"],
        clientId: DefaultFirebaseOptions.currentPlatform.iosClientId,
        hostedDomain: DefaultFirebaseOptions.currentPlatform.authDomain,
      );
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
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
  }

  Future<UserCredential> signInWithApple() async {
    final appleProvider = AppleAuthProvider();
    appleProvider.addScope('email');
    appleProvider.addScope('name');
    if (kIsWeb) {
      return await FirebaseAuth.instance.signInWithPopup(appleProvider);
    } else {
      return await FirebaseAuth.instance.signInWithProvider(appleProvider);
    }
  }

  Future signOut() async {
    try {
      // clear "from"
      return await _auth.signOut();
    } catch (error) {
      // TODO toast
      print(error.toString());
      return null;
    }
  }

  Future delete() async {
    try {
      return await _auth.currentUser?.delete();
    } catch (error) {
      // TODO toast
      print(error.toString());
      return null;
    }
  }

  Future resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Private method to retrieve custom claims of the current user
  Future<Map<String, dynamic>?> _getCustomClaims() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        // Force token refresh to get the latest claims
        IdTokenResult idTokenResult = await user.getIdTokenResult(true);
        return idTokenResult.claims;
      } catch (e) {
        print("Error retrieving custom claims: $e");
        // Handle errors appropriately in your app
      }
    }
    return null;
  }
}
