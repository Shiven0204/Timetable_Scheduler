import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:timetable_scheduler/screens/admin/dashboard_screen.dart';
import 'package:timetable_scheduler/screens/auth/login_screen.dart';

/// Routes the app root by [FirebaseAuth.authStateChanges]: dashboard when
/// signed in, [LoginScreen] when signed out.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data ?? FirebaseAuth.instance.currentUser;
        if (user != null) {
          return const DashboardScreen();
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return const LoginScreen();
      },
    );
  }
}
