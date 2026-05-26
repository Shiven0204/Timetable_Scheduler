import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:timetable_scheduler/models/app_user_profile.dart';
import 'package:timetable_scheduler/services/auth_service.dart';
import 'package:timetable_scheduler/widgets/missing_profile_screen.dart';

/// Guards a route by Firestore role (`users/{uid}.role`).
class RoleProtected extends StatefulWidget {
  const RoleProtected({
    super.key,
    required this.allowedRoles,
    required this.child,
  });

  final Set<String> allowedRoles;
  final Widget child;

  @override
  State<RoleProtected> createState() => _RoleProtectedState();
}

class _RoleProtectedState extends State<RoleProtected> {
  final _authService = AuthService();
  late final Future<ProfileLoadResult> _profileFuture;
  bool _deniedSnackShown = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _profileFuture = user != null
        ? _authService.fetchUserProfile(user)
        : Future.value(
            const ProfileLoadResult(
              status: ProfileLoadStatus.notFound,
              message: 'Not signed in',
            ),
          );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ProfileLoadResult>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final result = snapshot.data;
        final role = result?.profile?.role;
        final allowed =
            role != null && widget.allowedRoles.contains(role);

        if (allowed) return widget.child;

        if (!_deniedSnackShown) {
          _deniedSnackShown = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Access Denied')),
            );
          });
        }

        if (result != null && !result.isOk) {
          return MissingProfileScreen(
            message: result.message ?? 'Access Denied',
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Access Denied')),
          body: const Center(
            child: Text(
              'Access Denied',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        );
      },
    );
  }
}
