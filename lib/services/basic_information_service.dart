import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:timetable_scheduler/models/basic_information.dart';
import 'package:timetable_scheduler/models/schedule_slot.dart';

/// Persists [BasicInformation] and syncs engine fields to `config/timetable`.
class BasicInformationService {
  BasicInformationService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const _docPath = 'timetable_config/basic_information';

  DocumentReference<Map<String, dynamic>> get _docRef =>
      _db.doc(_docPath);

  Future<BasicInformation?> load() async {
    try {
      final snap = await _docRef.get();
      if (!snap.exists || snap.data() == null) {
        return null;
      }
      return BasicInformation.fromMap(snap.data()!);
    } catch (e, st) {
      debugPrint('load basic_information failed: $e\n$st');
      return null;
    }
  }

  Future<void> save(BasicInformation info) async {
    final data = {
      ...info.toMap(),
      'updated_at': FieldValue.serverTimestamp(),
    };
    await _docRef.set(data, SetOptions(merge: true));
    await _syncEngineConfig(info);
  }

  /// Writes working day count and period count for [TimetableService.getConfig].
  Future<void> _syncEngineConfig(BasicInformation info) async {
    final workingCount = info.workingDays.length.clamp(1, 7);
    final periodCount = _countPeriodsForEngine(info).clamp(1, 24);

    await _db.collection('config').doc('timetable').set(
      {
        'working_days': workingCount,
        'working_days_per_week': workingCount,
        'periods': periodCount,
        'periods_per_day': periodCount,
        'timetable_name': info.timetableName.trim(),
        'updated_at': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  int _countPeriodsForEngine(BasicInformation info) {
    if (info.scheduleMode == ScheduleMode.uniform) {
      return info.periods.length;
    }
    var max = 0;
    for (final day in info.workingDays) {
      final ds = info.daySchedules[day];
      if (ds != null && ds.periods.length > max) {
        max = ds.periods.length;
      }
    }
    return max > 0 ? max : info.periods.length;
  }

  /// Validates slots; returns error message or null if OK.
  static String? validateSlots(List<ScheduleSlot> slots, String sectionLabel) {
    for (final slot in slots) {
      if (slot.name.trim().isEmpty) {
        return '$sectionLabel: name is required';
      }
      if (!slot.isValid) {
        return '${slot.name}: end time must be after start time';
      }
    }
    return null;
  }

  /// Full form validation before save.
  static String? validate(BasicInformation info) {
    if (info.timetableName.trim().isEmpty) {
      return 'Timetable name is required';
    }
    if (info.workingDays.isEmpty) {
      return 'Select at least one working day';
    }
    if (info.scheduleType == ScheduleType.custom &&
        (info.cycleWeeks < 2 || info.cycleWeeks > 52)) {
      return 'Custom cycle weeks must be between 2 and 52';
    }

    final session = info.academicSession;
    if (session.hasAnyField && !session.isComplete) {
      return 'Complete all academic session fields or leave them empty';
    }
    if (session.isComplete &&
        session.endDate != null &&
        session.startDate != null &&
        !session.endDate!.isAfter(session.startDate!)) {
      return 'Session end date must be after start date';
    }

    if (info.scheduleMode == ScheduleMode.uniform) {
      final err = validateSlots(info.periods, 'Period') ??
          validateSlots(info.breaks, 'Break');
      if (err != null) return err;
    } else {
      for (final day in info.workingDays) {
        final ds = info.daySchedules[day] ?? DaySchedule();
        final err = validateSlots(ds.periods, '$day period') ??
            validateSlots(ds.breaks, '$day break');
        if (err != null) return err;
      }
    }

    return null;
  }
}
