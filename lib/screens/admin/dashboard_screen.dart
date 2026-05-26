import 'package:flutter/material.dart';
import 'package:timetable_scheduler/models/app_user_profile.dart';
import 'package:timetable_scheduler/routes/app_routes.dart';
import 'package:timetable_scheduler/widgets/logout_app_bar_action.dart';

/// Admin home — shown only when [AppUserProfile.role] is `admin` ([AuthGate]).
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, this.profile});

  final AppUserProfile? profile;

  static const _instituteName = 'Tech Institute';

  String _displayName() {
    final name = profile?.name.trim();
    if (name != null && name.isNotEmpty) return name;
    final email = profile?.email;
    if (email != null && email.isNotEmpty) {
      return email.split('@').first;
    }
    return 'Admin';
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
    final userName = _displayName();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: const [LogoutAppBarAction()],
      ),
      body: SingleChildScrollView(
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
              label: const Text('Admin'),
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
              'Quick actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            _AdminDashboardCards(scheme: scheme),
          ],
        ),
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
