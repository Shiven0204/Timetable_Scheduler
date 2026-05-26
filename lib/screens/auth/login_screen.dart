import 'dart:developer' as dev;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:timetable_scheduler/services/auth_service.dart';
import 'package:timetable_scheduler/utils/auth_error_messages.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  final _authService = AuthService();

  bool _loading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String label, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      suffixIcon: suffixIcon,
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _onLogin() async {
    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() => _loading = true);
    try {
      dev.log('Login attempt email=$email', name: 'LoginScreen');

      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'Sign-in succeeded but user is null.',
        );
      }

      dev.log('Firebase Auth OK uid=${user.uid}', name: 'LoginScreen');

      final profileResult = await _authService.fetchUserProfile(user);
      dev.log(
        'Profile load status=${profileResult.status}',
        name: 'LoginScreen',
      );

      if (!profileResult.isOk) {
        await _auth.signOut();
        if (!mounted) return;
        final msg = messageForMissingProfile(profileResult);
        setState(() => _errorMessage = msg);
        _showSnack(msg);
        return;
      }

      dev.log(
        'Login complete role=${profileResult.profile!.role}',
        name: 'LoginScreen',
      );
      // AuthGate rebuilds to role home.
    } on FirebaseAuthException catch (e) {
      dev.log('Auth error: ${e.code}', name: 'LoginScreen');
      if (!mounted) return;
      final msg = messageForFirebaseAuth(e);
      setState(() => _errorMessage = msg);
      _showSnack(msg);
    } catch (e) {
      dev.log('Login error: $e', name: 'LoginScreen');
      if (!mounted) return;
      const msg = 'Something went wrong. Please try again.';
      setState(() => _errorMessage = msg);
      _showSnack(msg);
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: scheme.primaryContainer
                                  .withValues(alpha: 0.35),
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
                                    color:
                                        Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
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
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    autocorrect: false,
                                    textInputAction: TextInputAction.next,
                                    enabled: !_loading,
                                    decoration:
                                        _inputDecoration('Email *'),
                                    validator: (value) {
                                      final v = value?.trim() ?? '';
                                      if (v.isEmpty) {
                                        return 'Email is required';
                                      }
                                      if (!RegExp(
                                        r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                      ).hasMatch(v)) {
                                        return 'Enter a valid email';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: _loading
                                        ? null
                                        : (_) => _onLogin(),
                                    enabled: !_loading,
                                    decoration: _inputDecoration(
                                      'Password *',
                                      suffixIcon: IconButton(
                                        tooltip: _obscurePassword
                                            ? 'Show password'
                                            : 'Hide password',
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword =
                                                !_obscurePassword;
                                          });
                                        },
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Password is required';
                                      }
                                      return null;
                                    },
                                  ),
                                  if (_errorMessage != null) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      _errorMessage!,
                                      style: TextStyle(
                                        color: scheme.error,
                                        fontSize: 13,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    height: 48,
                                    child: FilledButton(
                                      onPressed: _loading ? null : _onLogin,
                                      child: _loading
                                          ? const SizedBox(
                                              height: 22,
                                              width: 22,
                                              child:
                                                  CircularProgressIndicator(
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
                            'Admin · Faculty · Student',
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
              ),
            );
          },
        ),
      ),
    );
  }
}
