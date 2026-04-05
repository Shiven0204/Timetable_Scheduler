import 'package:flutter/material.dart';
import 'package:timetable_scheduler/routes/app_routes.dart';

class TimetableConfigScreen extends StatelessWidget {
  const TimetableConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timetable Configuration'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.addDepartment);
                  },
                  child: const Text('Department'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.addProgram);
                  },
                  child: const Text('Program'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
