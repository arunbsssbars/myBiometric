import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

class AuthNetworkException extends AuthException {
  const AuthNetworkException([
    super.message = 'No internet connection. Please check your network connection and try again.',
  ]);
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get current user stream
  Stream<User?> get userChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // Google Sign-In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        googleProvider.setCustomParameters({'prompt': 'select_account'});
        return await _auth.signInWithPopup(googleProvider);
      }

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        return null; // The user canceled the sign-in
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      return await _auth.signInWithCredential(credential);
    } on PlatformException catch (e) {
      debugPrint("PlatformException signing in with Google: $e");
      final errorString = e.toString().toLowerCase();
      final messageString = (e.message ?? '').toLowerCase();

      // Check for network errors (e.g. ApiException: 7 or network_error)
      if (e.code == 'network_error' ||
          e.message?.contains('7:') == true ||
          e.toString().contains('ApiException: 7') ||
          messageString.contains('network') ||
          errorString.contains('network')) {
        throw const AuthNetworkException(
          'No internet connection. Please check your network connection and try again.',
        );
      } else if (e.code == 'sign_in_canceled' || e.code == '12501') {
        return null; // User cancelled
      } else if (e.code == '10' || e.toString().contains('ApiException: 10')) {
        throw const AuthException(
          'Google Sign-In configuration error (missing SHA-1 in Firebase Console).',
        );
      }
      throw AuthException(
        e.message ?? 'Google Sign-In failed (${e.code}). Please try again.',
      );
    } on FirebaseAuthException catch (e) {
      debugPrint("FirebaseAuthException signing in with Google: $e");
      if (e.code == 'popup-closed-by-user' || e.code == 'cancelled') {
        return null; // User cancelled or closed the popup window
      }
      if (e.code == 'popup-blocked') {
        throw const AuthException(
          'Sign-in popup was blocked by your browser. Please allow popups for localhost and try again.',
        );
      }
      if (e.code == 'network-request-failed') {
        throw const AuthNetworkException(
          'Network connection error. Please check your internet connection and try again.',
        );
      }
      throw AuthException(e.message ?? 'Authentication error occurred.');
    } catch (e) {
      debugPrint("Error signing in with Google: $e");
      final errLower = e.toString().toLowerCase();
      if (errLower.contains('network_error') ||
          errLower.contains('apiexception: 7') ||
          errLower.contains('socketexception') ||
          errLower.contains('network')) {
        throw const AuthNetworkException(
          'No internet connection. Please check your network connection and try again.',
        );
      }
      throw AuthException('Google Sign-In failed: $e');
    }
  }

  // Email & Password Sign-In
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'network-request-failed') {
        throw const AuthNetworkException(
          'No internet connection. Please check your network and try again.',
        );
      }
      throw AuthException(e.message ?? 'Failed to sign in.');
    } catch (e) {
      if (e.toString().toLowerCase().contains('network')) {
        throw const AuthNetworkException(
          'No internet connection. Please check your network and try again.',
        );
      }
      rethrow;
    }
  }

  // Email & Password Registration
  Future<UserCredential?> registerWithEmail(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'network-request-failed') {
        throw const AuthNetworkException(
          'No internet connection. Please check your network and try again.',
        );
      }
      throw AuthException(e.message ?? 'Registration failed.');
    } catch (e) {
      if (e.toString().toLowerCase().contains('network')) {
        throw const AuthNetworkException(
          'No internet connection. Please check your network and try again.',
        );
      }
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    if (!kIsWeb) {
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
    }
    await _auth.signOut();
  }
}
