// lib/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<User?> signInWithGoogle() async {
    try {
      // 1. Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // If the user cancels the sign-in, return null
      if (googleUser == null) {
        return null;
      }

      // 2. Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Create a new credential for Firebase
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Sign in to Firebase with the credential
      final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);

      // Return the user from the UserCredential
      return userCredential.user;
    } catch (e) {
      // Handle errors (e.g., network issues)
      print(e);
      return null;
    }
  }

  // Method to sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut(); // Sign out from Google
    await _firebaseAuth.signOut(); // Sign out from Firebase
  }
}
