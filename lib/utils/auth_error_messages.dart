import 'package:firebase_auth/firebase_auth.dart';
import 'package:timetable_scheduler/models/app_user_profile.dart';

/// User-readable copy when Firestore profile is missing or invalid.
String messageForMissingProfile(ProfileLoadResult result) {
  switch (result.status) {
    case ProfileLoadStatus.notFound:
      return 'Account not set up. An admin must create your profile in Firestore (users/your-uid with role admin, faculty, or student).';
    case ProfileLoadStatus.invalidRole:
      return result.message ??
          'Your account role is invalid. Use admin, faculty, or student.';
    case ProfileLoadStatus.firestoreError:
      return result.message ??
          'Could not load your profile. Check Firestore rules and connection.';
    case ProfileLoadStatus.found:
      return 'Unexpected profile error.';
  }
}

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
