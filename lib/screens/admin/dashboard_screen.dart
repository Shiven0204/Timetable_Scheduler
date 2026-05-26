import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:timetable_scheduler/screens/auth/login_screen.dart';
import 'package:timetable_scheduler/routes/app_routes.dart';
import 'package:timetable_scheduler/services/auth_service.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static const _instituteName = 'Tech Institute';

  String _displayName(User? user) {
    if (user == null) return 'User';
    final name = user.displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final email = user.email?.trim();
    if (email != null && email.isNotEmpty) {
      final local = email.split('@').first;
      if (local.isNotEmpty) return local;
    }
    return 'User';
  }

  String _roleLabel(String? role) {
    if (role == null) return 'Unknown';
    final r = role.trim().toLowerCase();
    if (r == 'admin') return 'Admin';
    if (r == 'faculty') return 'Faculty';
    if (r == 'student') return 'Student';
    return r.isEmpty ? 'Unknown' : r[0].toUpperCase() + r.substring(1);
  }

  String _greetingForNow() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final greeting = _greetingForNow();
    final user = FirebaseAuth.instance.currentUser;
    final userName = _displayName(user);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              // Clear the navigation stack to prevent back-navigation into protected screens.
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => const LoginScreen(),
                ),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<String?>(
        future: AuthService().getCurrentUserRole(),
        builder: (context, snapshot) {
          final role = snapshot.data;

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (role == null) {
            return const Center(child: Text('Access Denied'));
          }

          final roleLabel = _roleLabel(role);
          final showAdmin = role == 'admin';
          final showFaculty = role == 'faculty';
          final showStudent = role == 'student';
          final isKnownRole = showAdmin || showFaculty || showStudent;
          if (!isKnownRole) {
            return const Center(child: Text('Access Denied'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting, $userName',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  _instituteName,
                  style: TextStyle(
                    fontSize: 15,
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Chip(
                  label: Text(roleLabel),
                  avatar: Icon(
                    Icons.verified_user_outlined,
                    size: 18,
                    color: scheme.primary,
                  ),
                  visualDensity: VisualDensity.compact,
                  side: BorderSide(color: scheme.outlineVariant),
                ),
                const SizedBox(height: 28),
                Text(
                  'Dashboard',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),

                if (showAdmin) ...[
                  _AdminDashboardCards(scheme: scheme),
                ] else if (showFaculty) ...[
                  _FacultyDashboardCards(scheme: scheme),
                ] else if (showStudent) ...[
                  _StudentDashboardCards(scheme: scheme),
                ] else ...[
                  const SizedBox.shrink(),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AdminDashboardCards extends StatelessWidget {
  const _AdminDashboardCards({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                title: 'My Timetables',
                subtitle: 'Manage drafts & published',
                icon: Icons.grid_view_rounded,
                gradient: LinearGradient(
                  colors: [
                    scheme.primary,
                    Color.lerp(scheme.primary, scheme.tertiary, 0.35)!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                onTap: () => Navigator.pushNamed(context, AppRoutes.myTimetables),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                title: 'View Calendar',
                subtitle: 'Weekly grid by program',
                icon: Icons.calendar_month_rounded,
                gradient: LinearGradient(
                  colors: [
                    scheme.tertiary,
                    Color.lerp(scheme.tertiary, scheme.secondary, 0.25)!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                onTap: () => Navigator.pushNamed(context, AppRoutes.calendar),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                title: 'Overview',
                subtitle: 'Data input & system overview',
                icon: Icons.storage,
                gradient: LinearGradient(
                  colors: [
                    scheme.primaryContainer,
                    Color.lerp(scheme.primary, scheme.tertiary, 0.4)!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                onTap: () => Navigator.pushNamed(context, AppRoutes.overview),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                title: 'Generate Timetable',
                subtitle: 'Configure & run scheduling engine',
                icon: Icons.auto_fix_high,
                gradient: LinearGradient(
                  colors: [
                    scheme.secondary,
                    Color.lerp(scheme.secondary, scheme.primary, 0.35)!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.timetableConfig),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FacultyDashboardCards extends StatelessWidget {
  const _FacultyDashboardCards({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            title: 'My Schedule',
            subtitle: 'Faculty weekly timetable',
            icon: Icons.person,
            gradient: LinearGradient(
              colors: [
                scheme.primary,
                Color.lerp(scheme.primary, scheme.tertiary, 0.35)!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            onTap: () => Navigator.pushNamed(context, AppRoutes.facultySchedule),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionCard(
            title: 'View Calendar',
            subtitle: 'Weekly grid by program',
            icon: Icons.calendar_month_rounded,
            gradient: LinearGradient(
              colors: [
                scheme.tertiary,
                Color.lerp(scheme.tertiary, scheme.secondary, 0.25)!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            onTap: () => Navigator.pushNamed(context, AppRoutes.calendar),
          ),
        ),
      ],
    );
  }
}

class _StudentDashboardCards extends StatelessWidget {
  const _StudentDashboardCards({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            title: 'View Timetable',
            subtitle: 'Weekly timetable by program',
            icon: Icons.table_chart,
            gradient: LinearGradient(
              colors: [
                scheme.primary,
                Color.lerp(scheme.primary, scheme.tertiary, 0.35)!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            onTap: () => Navigator.pushNamed(context, AppRoutes.viewTimetable),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickActionCard(
            title: 'Calendar',
            subtitle: 'Weekly grid view',
            icon: Icons.calendar_month_rounded,
            gradient: LinearGradient(
              colors: [
                scheme.tertiary,
                Color.lerp(scheme.tertiary, scheme.secondary, 0.25)!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            onTap: () => Navigator.pushNamed(context, AppRoutes.calendar),
          ),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: gradient,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: Colors.white, size: 28),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
