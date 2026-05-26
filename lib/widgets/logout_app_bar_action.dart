import 'package:flutter/material.dart';
import 'package:timetable_scheduler/services/auth_service.dart';

/// Signs out via Firebase; [AuthGate] returns to login.
class LogoutAppBarAction extends StatelessWidget {
  const LogoutAppBarAction({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Sign out',
      icon: const Icon(Icons.logout_rounded),
      onPressed: () => AuthService().signOut(),
    );
  }
}
