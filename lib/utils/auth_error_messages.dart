import 'package:firebase_auth/firebase_auth.dart';

/// User-readable copy for common [FirebaseAuthException] codes.
String messageForFirebaseAuth(FirebaseAuthException e) {
  switch (e.code) {
    case 'wrong-password':
    case 'invalid-credential':
      return 'Incorrect email or password. Please try again.';
    case 'user-not-found':
      return 'No account found for this email.';
    case 'invalid-email':
      return 'Please enter a valid email address.';
    case 'user-disabled':
      return 'This account has been disabled.';
    case 'too-many-requests':
      return 'Too many attempts. Please wait a moment and try again.';
    case 'network-request-failed':
      return 'Network error. Check your connection and try again.';
    case 'operation-not-allowed':
      return 'Email/password sign-in is not enabled for this project.';
    default:
      return e.message?.trim().isNotEmpty == true
          ? e.message!.trim()
          : 'Sign in failed. Please try again.';
  }
}
