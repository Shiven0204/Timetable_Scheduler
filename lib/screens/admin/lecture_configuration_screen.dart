import 'package:flutter/material.dart';
import 'package:timetable_scheduler/routes/app_routes.dart';

class LectureConfigurationScreen extends StatelessWidget {
  const LectureConfigurationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lecture Configuration'),
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
                    Navigator.pushNamed(context, AppRoutes.addMapping);
                  },
                  child: const Text('Mapping'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.timetableConfig);
                  },
                  child: const Text('Timetable Settings'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

