import 'package:flutter/material.dart';
import 'package:timetable_scheduler/routes/app_routes.dart';
import 'package:timetable_scheduler/screens/admin/add_department_screen.dart';
import 'package:timetable_scheduler/screens/admin/add_program_screen.dart';
import 'package:timetable_scheduler/screens/admin/dashboard_screen.dart';
import 'package:timetable_scheduler/screens/admin/timetable_config_screen.dart';
import 'package:timetable_scheduler/screens/auth/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.login,
      routes: {
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.dashboard: (context) => const DashboardScreen(),
        AppRoutes.timetableConfig: (context) => const TimetableConfigScreen(),
        AppRoutes.addDepartment: (context) => const AddDepartmentScreen(),
        AppRoutes.addProgram: (context) => const AddProgramScreen(),
      },
    );
  }
}
