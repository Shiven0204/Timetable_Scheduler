import 'dart:developer' as dev;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timetable_scheduler/models/app_user_profile.dart';

/// Reads the signed-in user's role from Firestore (`users` collection).
///
/// Document id must be the Firebase Auth **uid** (not email).
class AuthService {
  AuthService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  static const _logName = 'AuthService';

  User? get currentUser => _auth.currentUser;

  Future<void> signOut() async {
    dev.log('Signing out', name: _logName);
    await _auth.signOut();
  }

  /// Loads `users/{uid}` and normalizes role.
  Future<ProfileLoadResult> fetchUserProfile(User user) async {
    final uid = user.uid;
    dev.log('Fetching profile for uid=$uid email=${user.email}', name: _logName);

    try {
      final snap = await _db.collection('users').doc(uid).get();

      if (!snap.exists) {
        dev.log('No Firestore document at users/$uid', name: _logName);
        return ProfileLoadResult(
          status: ProfileLoadStatus.notFound,
          message:
              'No user profile found. Create users/$uid in Firestore with role admin, faculty, or student.',
        );
      }

      final data = snap.data();
      if (data == null || data.isEmpty) {
        return const ProfileLoadResult(
          status: ProfileLoadStatus.notFound,
          message: 'User profile document is empty.',
        );
      }

      final profile = AppUserProfile.fromFirestore(uid: uid, data: data);

      if (!AppUserProfile.knownRoles.contains(profile.role)) {
        dev.log('Invalid role: ${profile.role}', name: _logName);
        return ProfileLoadResult(
          status: ProfileLoadStatus.invalidRole,
          message:
              'Invalid role "${profile.role}". Use admin, faculty, or student.',
          profile: profile,
        );
      }

      dev.log('Profile OK role=${profile.role}', name: _logName);
      return ProfileLoadResult(
        status: ProfileLoadStatus.found,
        profile: profile,
      );
    } on FirebaseException catch (e) {
      dev.log('Firestore error: ${e.code} ${e.message}', name: _logName);
      return ProfileLoadResult(
        status: ProfileLoadStatus.firestoreError,
        message: e.message ?? 'Could not load user profile (${e.code}).',
      );
    } catch (e, st) {
      dev.log('Profile load failed', error: e, stackTrace: st, name: _logName);
      return ProfileLoadResult(
        status: ProfileLoadStatus.firestoreError,
        message: 'Could not load user profile.',
      );
    }
  }

  Future<String?> getCurrentUserRole() async {
    final user = currentUser;
    if (user == null) return null;
    final result = await fetchUserProfile(user);
    return result.profile?.role;
  }

  Future<bool> isAdmin() async =>
      (await getCurrentUserRole()) == AppUserProfile.roleAdmin;

  Future<bool> isFaculty() async =>
      (await getCurrentUserRole()) == AppUserProfile.roleFaculty;

  Future<bool> isStudent() async =>
      (await getCurrentUserRole()) == AppUserProfile.roleStudent;
}
