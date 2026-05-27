import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:timetable_scheduler/routes/app_routes.dart';
import 'package:timetable_scheduler/screens/admin/add_subject_screen.dart';
import 'package:timetable_scheduler/screens/admin/dashboard_screen.dart';
import 'package:timetable_scheduler/screens/admin/institute_data_screen.dart';
import 'package:timetable_scheduler/screens/admin/lecture_configuration_screen.dart';
import 'package:timetable_scheduler/screens/admin/my_timetables_screen.dart';
import 'package:timetable_scheduler/screens/admin/basic_information_screen.dart';
import 'package:timetable_scheduler/screens/admin/overview_screen.dart';
import 'package:timetable_scheduler/screens/admin/timetable_config_screen.dart';
import 'package:timetable_scheduler/widgets/auth_gate.dart';
import 'package:timetable_scheduler/screens/admin/add_mapping_screen.dart';
import 'package:timetable_scheduler/screens/faculty/faculty_schedule_screen.dart';
import 'package:timetable_scheduler/screens/calendar/calendar_screen.dart';
import 'package:timetable_scheduler/screens/student/view_timetable_screen.dart';
import 'package:timetable_scheduler/widgets/role_protected.dart';

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
      home: const AuthGate(),
      routes: {
        // Home route (role-aware dashboard; all roles allowed).
        AppRoutes.dashboard: (context) => RoleProtected(
              allowedRoles: {'admin', 'faculty', 'student'},
              child: DashboardScreen(),
            ),

        // Admin-only screens.
        AppRoutes.overview: (context) => RoleProtected(
              allowedRoles: {'admin'},
              child: OverviewScreen(),
            ),
        AppRoutes.basicInformation: (context) => RoleProtected(
              allowedRoles: {'admin'},
              child: BasicInformationScreen(),
            ),
        AppRoutes.timetableConfig: (context) => RoleProtected(
              allowedRoles: {'admin'},
              child: TimetableConfigScreen(),
            ),
        AppRoutes.addSubject: (context) => RoleProtected(
              allowedRoles: {'admin'},
              child: AddSubjectScreen(),
            ),
        AppRoutes.addMapping: (context) => RoleProtected(
              allowedRoles: {'admin'},
              child: AddMappingScreen(),
            ),
        AppRoutes.instituteData: (context) => RoleProtected(
              allowedRoles: {'admin'},
              child: InstituteDataScreen(),
            ),
        AppRoutes.lectureConfiguration: (context) => RoleProtected(
              allowedRoles: {'admin'},
              child: LectureConfigurationScreen(),
            ),
        AppRoutes.myTimetables: (context) => RoleProtected(
              allowedRoles: {'admin'},
              child: MyTimetablesScreen(),
            ),
        AppRoutes.viewTimetable: (context) => RoleProtected(
              allowedRoles: {'admin', 'student'},
              child: ViewTimetableScreen(),
            ),

        // Faculty screens (faculty/admin).
        AppRoutes.facultySchedule: (context) => RoleProtected(
              allowedRoles: {'admin', 'faculty'},
              child: FacultyScheduleScreen(),
            ),

        // Calendar is allowed for all roles.
        AppRoutes.calendar: (context) => const CalendarScreen(),
      },
    );
  }
}