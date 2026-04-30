import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:timetable_scheduler/routes/app_routes.dart';
import 'package:timetable_scheduler/screens/admin/add_department_screen.dart';
import 'package:timetable_scheduler/screens/admin/add_faculty_screen.dart';
import 'package:timetable_scheduler/screens/admin/add_program_screen.dart';
import 'package:timetable_scheduler/screens/admin/add_room_screen.dart';
import 'package:timetable_scheduler/screens/admin/add_subject_screen.dart';
import 'package:timetable_scheduler/screens/admin/dashboard_screen.dart';
import 'package:timetable_scheduler/screens/admin/overview_screen.dart';
import 'package:timetable_scheduler/screens/admin/timetable_config_screen.dart';
import 'package:timetable_scheduler/screens/auth/login_screen.dart';
import 'package:timetable_scheduler/screens/admin/add_mapping_screen.dart';
import 'package:timetable_scheduler/screens/student/view_timetable_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
        AppRoutes.overview: (context) => const OverviewScreen(),
        AppRoutes.timetableConfig: (context) => const TimetableConfigScreen(),
        AppRoutes.addDepartment: (context) => const AddDepartmentScreen(),
        AppRoutes.addProgram: (context) => const AddProgramScreen(),
        AppRoutes.addFaculty: (context) => const AddFacultyScreen(),
        AppRoutes.addSubject: (context) => const AddSubjectScreen(),
        AppRoutes.addRoom: (context) => const AddRoomScreen(),
        AppRoutes.addMapping: (context) => const AddMappingScreen(),
        AppRoutes.viewTimetable: (context) => const ViewTimetableScreen(),
      },
    );
  }
}