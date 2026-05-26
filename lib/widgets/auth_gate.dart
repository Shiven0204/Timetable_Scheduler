import 'dart:async';
import 'dart:developer' as dev;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:timetable_scheduler/models/app_user_profile.dart';
import 'package:timetable_scheduler/screens/admin/dashboard_screen.dart';
import 'package:timetable_scheduler/screens/auth/login_screen.dart';
import 'package:timetable_scheduler/screens/faculty/faculty_schedule_screen.dart';
import 'package:timetable_scheduler/screens/student/view_timetable_screen.dart';
import 'package:timetable_scheduler/services/auth_service.dart';
import 'package:timetable_scheduler/widgets/missing_profile_screen.dart';

/// Listens to Firebase Auth, loads `users/{uid}`, routes home by role.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _authService = AuthService();
  StreamSubscription<User?>? _authSub;

  User? _user;
  ProfileLoadResult? _profileResult;
  bool _loadingProfile = true;

  @override
  void initState() {
    super.initState();
    _authSub = FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _onAuthChanged(User? user) async {
    dev.log('authStateChanged uid=${user?.uid}', name: 'AuthGate');

    setState(() {
      _user = user;
      _profileResult = null;
      _loadingProfile = user != null;
    });

    if (user == null) {
      setState(() => _loadingProfile = false);
      return;
    }

    final result = await _authService.fetchUserProfile(user);
    dev.log(
      'profile status=${result.status} role=${result.profile?.role}',
      name: 'AuthGate',
    );

    if (!mounted) return;
    setState(() {
      _profileResult = result;
      _loadingProfile = false;
    });
  }

  Widget _homeForRole(AppUserProfile profile) {
    dev.log('Navigate home → ${profile.role}', name: 'AuthGate');
    switch (profile.role) {
      case AppUserProfile.roleAdmin:
        return DashboardScreen(profile: profile);
      case AppUserProfile.roleFaculty:
        return FacultyScheduleScreen(profile: profile);
      case AppUserProfile.roleStudent:
        return ViewTimetableScreen(profile: profile);
      default:
        return MissingProfileScreen(
          message: 'Invalid role "${profile.role}".',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const LoginScreen();
    }

    if (_loadingProfile || _profileResult == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final result = _profileResult!;
    if (result.isOk && result.profile != null) {
      return _homeForRole(result.profile!);
    }

    return MissingProfileScreen(
      message: result.message ??
          'Your account is not configured. Contact an administrator.',
    );
  }
}
