/// Firestore `users/{uid}` profile linked to Firebase Auth.
class AppUserProfile {
  const AppUserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
  });

  final String uid;
  final String name;
  final String email;
  /// Normalized: `admin`, `faculty`, or `student`.
  final String role;

  bool get isAdmin => role == AppUserProfile.roleAdmin;
  bool get isFaculty => role == AppUserProfile.roleFaculty;
  bool get isStudent => role == AppUserProfile.roleStudent;

  static const roleAdmin = 'admin';
  static const roleFaculty = 'faculty';
  static const roleStudent = 'student';

  static const knownRoles = {roleAdmin, roleFaculty, roleStudent};

  factory AppUserProfile.fromFirestore({
    required String uid,
    required Map<String, dynamic> data,
  }) {
    return AppUserProfile(
      uid: uid,
      name: (data['name'] ?? '').toString().trim(),
      email: (data['email'] ?? '').toString().trim(),
      role: (data['role'] ?? '').toString().trim().toLowerCase(),
    );
  }
}

enum ProfileLoadStatus { found, notFound, invalidRole, firestoreError }

class ProfileLoadResult {
  const ProfileLoadResult({
    required this.status,
    this.profile,
    this.message,
  });

  final ProfileLoadStatus status;
  final AppUserProfile? profile;
  final String? message;

  bool get isOk => status == ProfileLoadStatus.found && profile != null;
}
