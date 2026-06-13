import 'package:flutter/material.dart';
import 'package:timetable_scheduler/models/basic_information.dart';
import 'package:timetable_scheduler/screens/admin/bell_schedule_form.dart';
import 'package:timetable_scheduler/screens/admin/timetable_details_form.dart';
import 'package:timetable_scheduler/services/basic_information_service.dart';
import 'package:timetable_scheduler/widgets/institute_data/institute_entry_sheet.dart';

/// Opens Basic Information entry sheets from [BasicInformationScreen].
class BasicInformationEntries {
  BasicInformationEntries._();

  static void _showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  static Future<BasicInformation> _loadBase() async {
    final service = BasicInformationService();
    return await service.load() ?? BasicInformation();
  }

  static Future<void> openTimetableDetails(
    BuildContext context, {
    VoidCallback? onSaved,
  }) async {
    final base = await _loadBase();
    if (!context.mounted) return;

    final formKey = GlobalKey<TimetableDetailsFormState>();
    final ok = await showInstituteEntrySheet(
      context: context,
      title: 'Timetable Details',
      subtitle: 'Name, description, and academic session',
      builder: (_) => TimetableDetailsForm(
        key: formKey,
        baseInfo: base,
        embeddedInDialog: true,
      ),
      onSubmit: () => formKey.currentState?.submit() ?? Future.value(false),
    );

    if (ok && context.mounted) {
      _showSuccess(context, 'Timetable details saved');
      onSaved?.call();
    }
  }

  static Future<void> openBellSchedule(
    BuildContext context, {
    VoidCallback? onSaved,
  }) async {
    final base = await _loadBase();
    if (!context.mounted) return;

    final formKey = GlobalKey<BellScheduleFormState>();
    final ok = await showInstituteEntrySheet(
      context: context,
      title: 'Bell Schedule',
      subtitle: 'Schedule type, working days, periods & breaks',
      builder: (_) => BellScheduleForm(
        key: formKey,
        baseInfo: base,
        embeddedInDialog: true,
      ),
      onSubmit: () => formKey.currentState?.submit() ?? Future.value(false),
    );

    if (ok && context.mounted) {
      _showSuccess(context, 'Bell schedule saved');
      onSaved?.call();
    }
  }
}
