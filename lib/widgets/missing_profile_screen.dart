import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:timetable_scheduler/services/auth_service.dart';

/// Shown when Firebase Auth succeeded but `users/{uid}` is missing or invalid.
class MissingProfileScreen extends StatelessWidget {
  const MissingProfileScreen({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '—';
    final email = FirebaseAuth.instance.currentUser?.email ?? '—';

    return Scaffold(
      appBar: AppBar(title: const Text('Account setup required')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.person_off_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 15, height: 1.45),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Email: $email', style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 6),
                    SelectableText(
                      'Firestore path: users/$uid',
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => AuthService().signOut(),
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}
