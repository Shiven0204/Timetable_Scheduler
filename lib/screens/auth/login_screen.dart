import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:timetable_scheduler/utils/auth_error_messages.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    );
  }

  bool _isValidEmailFormat(String email) {
    final trimmed = email.trim();
    if (trimmed.isEmpty) return false;
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmed);
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _onLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty) {
      _showSnack('Please enter your email.');
      return;
    }
    if (!_isValidEmailFormat(email)) {
      _showSnack('Please enter a valid email address.');
      return;
    }
    if (password.isEmpty) {
      _showSnack('Please enter your password.');
      return;
    }

    setState(() => _loading = true);
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      if (!mounted) return;
      // [AuthGate] rebuilds to dashboard when auth state updates.
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showSnack(messageForFirebaseAuth(e));
    } catch (e) {
      if (!mounted) return;
      _showSnack('Something went wrong. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final primaryColor = scheme.primary;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 32,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer.withValues(alpha: 0.35),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.calendar_month_rounded,
                            size: 44,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Timetable Scheduler',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Smart Academic Scheduling System',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.35,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Sign in',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                TextField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  autocorrect: false,
                                  textInputAction: TextInputAction.next,
                                  enabled: !_loading,
                                  decoration: _inputDecoration('Email'),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _passwordController,
                                  obscureText: true,
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: _loading ? null : (_) => _onLogin(),
                                  enabled: !_loading,
                                  decoration: _inputDecoration('Password'),
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  height: 48,
                                  child: FilledButton(
                                    onPressed: _loading ? null : _onLogin,
                                    child: _loading
                                        ? const SizedBox(
                                            height: 22,
                                            width: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text('Login'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          'Administrator access',
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Version 1.0.0',
                          style: TextStyle(
                            fontSize: 11,
                            color: scheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
