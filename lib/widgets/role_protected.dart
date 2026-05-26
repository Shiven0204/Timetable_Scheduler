import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:timetable_scheduler/screens/auth/login_screen.dart';
import 'package:timetable_scheduler/services/auth_service.dart';

/// Guards a route/screen by checking Firestore role (`users/{uid}.role`).
///
/// If the role is not allowed, shows a snackbar "Access Denied" and displays
/// an access denied view.
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
  bool _deniedSnackShown = false;

  Future<Widget> _unauthorizedFallback() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const LoginScreen();
    }

    if (!_deniedSnackShown) {
      _deniedSnackShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Access Denied')),
        );
      });
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
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _authService.getCurrentUserRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final role = snapshot.data;
        final allowed = role != null && widget.allowedRoles.contains(role);
        if (allowed) return widget.child;

        return FutureBuilder<Widget>(
          future: _unauthorizedFallback(),
          builder: (context, deniedSnap) {
            if (deniedSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return deniedSnap.data ?? const SizedBox.shrink();
          },
        );
      },
    );
  }
}

