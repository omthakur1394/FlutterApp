// lib/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<User?> signInWithGoogle() async {
    try {
      // **NEW:** Attempt to sign out from GoogleSignIn first
      // This can help prompt the account chooser if an account was previously selected.
      await _googleSignIn.signOut(); 
      print('[AuthService] Attempted _googleSignIn.signOut() before new sign-in.');

      // 1. Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      print('[AuthService] _googleSignIn.signIn() completed. User selected: ${googleUser?.email}');


      // If the user cancels the sign-in, return null
      if (googleUser == null) {
        print('[AuthService] Google sign-in cancelled by user.');
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
      print('[AuthService] Signing into Firebase with Google credential...');
      final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
      print('[AuthService] Firebase sign-in successful. User: ${userCredential.user?.uid}');


      // Return the user from the UserCredential
      return userCredential.user;
    } catch (e) {
      // Handle errors (e.g., network issues)
      print('[AuthService] Error during Google Sign-In: $e');
      return null;
    }
  }

  // Method to sign out from Firebase and Google
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      print('[AuthService] Signed out from GoogleSignIn.');
    } catch (e) {
      print('[AuthService] Error signing out from GoogleSignIn: $e');
    }
    try {
      await _firebaseAuth.signOut();
      print('[AuthService] Signed out from FirebaseAuth.');
    } catch (e) {
      print('[AuthService] Error signing out from FirebaseAuth: $e');
    }
  }
}
