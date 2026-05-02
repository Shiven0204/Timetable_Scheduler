import 'package:flutter/material.dart';
import 'package:timetable_scheduler/routes/app_routes.dart';

class InstituteDataScreen extends StatelessWidget {
  const InstituteDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Institute Data'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Manage Institute Data',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 18),
              _tile(context, 'Department', Icons.account_tree, AppRoutes.addDepartment),
              const SizedBox(height: 14),
              _tile(context, 'Program', Icons.school, AppRoutes.addProgram),
              const SizedBox(height: 14),
              _tile(context, 'Faculty', Icons.person, AppRoutes.addFaculty),
              const SizedBox(height: 14),
              _tile(context, 'Subject', Icons.menu_book, AppRoutes.addSubject),
              const SizedBox(height: 14),
              _tile(context, 'Room', Icons.meeting_room, AppRoutes.addRoom),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    String title,
    IconData icon,
    String route,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Navigator.pushNamed(context, route),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Row(
              children: [
                Icon(icon),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

