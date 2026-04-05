import 'package:flutter/material.dart';
import 'package:timetable_scheduler/routes/app_routes.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.timetableConfig);
              },
              child: const Text('My Timetable'),
            ),
          ),
        ),
      ),
    );
  }
}
