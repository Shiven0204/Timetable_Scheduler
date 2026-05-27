import 'package:flutter/material.dart';
import 'package:timetable_scheduler/screens/admin/add_department_screen.dart';
import 'package:timetable_scheduler/screens/admin/add_faculty_screen.dart';
import 'package:timetable_scheduler/screens/admin/add_program_screen.dart';
import 'package:timetable_scheduler/screens/admin/add_room_screen.dart';
import 'package:timetable_scheduler/widgets/institute_data/institute_entry_sheet.dart';

/// Opens institute data entry sheets from [InstituteDataScreen].
class InstituteDataEntries {
  InstituteDataEntries._();

  static void _showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  static Future<void> openDepartment(BuildContext context) async {
    final formKey = GlobalKey<AddDepartmentScreenState>();
    final ok = await showInstituteEntrySheet(
      context: context,
      title: 'Department',
      subtitle: 'Add a new department',
      builder: (_) => AddDepartmentScreen(
        key: formKey,
        embeddedInDialog: true,
      ),
      onSubmit: () => formKey.currentState?.submit() ?? Future.value(false),
    );
    if (ok && context.mounted) {
      _showSuccess(context, 'Department saved');
    }
  }

  static Future<void> openProgram(BuildContext context) async {
    final formKey = GlobalKey<AddProgramScreenState>();
    final ok = await showInstituteEntrySheet(
      context: context,
      title: 'Program',
      subtitle: 'Name, short name, and student count',
      builder: (_) => AddProgramScreen(
        key: formKey,
        embeddedInDialog: true,
      ),
      onSubmit: () => formKey.currentState?.submit() ?? Future.value(false),
    );
    if (ok && context.mounted) {
      _showSuccess(context, 'Program saved');
    }
  }

  static Future<void> openFaculty(BuildContext context) async {
    final formKey = GlobalKey<AddFacultyScreenState>();
    final ok = await showInstituteEntrySheet(
      context: context,
      title: 'Faculty',
      subtitle: 'Workload, department, and availability',
      builder: (_) => AddFacultyScreen(
        key: formKey,
        embeddedInDialog: true,
      ),
      onSubmit: () => formKey.currentState?.submit() ?? Future.value(false),
    );
    if (ok && context.mounted) {
      _showSuccess(context, 'Faculty saved');
    }
  }

  static Future<void> openRoom(BuildContext context) async {
    final formKey = GlobalKey<AddRoomScreenState>();
    final ok = await showInstituteEntrySheet(
      context: context,
      title: 'Room',
      subtitle: 'Classroom or lab with capacity',
      builder: (_) => AddRoomScreen(
        key: formKey,
        embeddedInDialog: true,
      ),
      onSubmit: () => formKey.currentState?.submit() ?? Future.value(false),
    );
    if (ok && context.mounted) {
      _showSuccess(context, 'Room saved');
    }
  }
}
