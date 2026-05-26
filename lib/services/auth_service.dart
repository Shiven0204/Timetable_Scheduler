import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Reads the signed-in user's role from Firestore (`users` collection).
///
/// Expected document shape in `users/{uid}`:
/// - uid
/// - name
/// - email
/// - role: 'admin' | 'faculty' | 'student'
class AuthService {
  AuthService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Future<String?> getCurrentUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final snap = await _db.collection('users').doc(user.uid).get();
    if (!snap.exists) return null;

    final data = snap.data();
    final rawRole = data?['role'];
    if (rawRole == null) return null;

    return rawRole.toString().trim().toLowerCase();
  }

  Future<bool> isAdmin() async => (await getCurrentUserRole()) == 'admin';
  Future<bool> isFaculty() async => (await getCurrentUserRole()) == 'faculty';
  Future<bool> isStudent() async => (await getCurrentUserRole()) == 'student';
}

