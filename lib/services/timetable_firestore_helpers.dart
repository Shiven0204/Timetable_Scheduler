import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timetable_scheduler/services/timetable_name_resolver.dart';

/// Builds in-memory grids from flat `timetable` collection documents.
class TimetableFirestoreHelpers {
  TimetableFirestoreHelpers._();

  static int? parseDayIndex(Object? dayValue, int dayCount) {
    final dayIndex = dayValue is num
        ? dayValue.toInt()
        : int.tryParse('$dayValue');

    if (dayIndex == null || dayIndex < 0 || dayIndex >= dayCount) {
      return null;
    }

    return dayIndex;
  }

  static int? parsePeriodIndex(Object? periodValue, int periodsPerDay) {
    final periodIndex = periodValue is num
        ? periodValue.toInt()
        : int.tryParse('$periodValue');

    if (periodIndex == null ||
        periodIndex < 0 ||
        periodIndex >= periodsPerDay) {
      return null;
    }

    return periodIndex;
  }

  static Map<String, List<Map<String, dynamic>?>> emptyGridForDays({
    required List<String> orderedDayNames,
    required int periodsPerDay,
  }) {
    return {
      for (final d in orderedDayNames)
        d: List<Map<String, dynamic>?>.filled(periodsPerDay, null),
    };
  }

  static bool isGridEmpty(Map<String, List<Map<String, dynamic>?>> grid) {
    for (final row in grid.values) {
      if (row.any((cell) => cell != null)) {
        return false;
      }
    }
    return true;
  }

  /// Student / Calendar View
  static Map<String, List<Map<String, dynamic>?>> buildProgramViewGrid({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    required List<String> orderedDayNames,
    required int periodsPerDay,
    required TimetableResolvedNames names,
    required List<int> breakIndexes,
  }) {
    final grid = emptyGridForDays(
      orderedDayNames: orderedDayNames,
      periodsPerDay: periodsPerDay,
    );

    for (final doc in docs) {
      final data = doc.data();

      final dayIndex =
          parseDayIndex(data['day'], orderedDayNames.length);

      final parsedPeriodIndex =
          parsePeriodIndex(data['period'], periodsPerDay);

      if (dayIndex == null || parsedPeriodIndex == null) {
        continue;
      }

      int periodIndex = parsedPeriodIndex;

      for (final breakIndex in breakIndexes) {
        if (periodIndex >= breakIndex) {
          periodIndex++;
        }
      }

      if (periodIndex >= periodsPerDay) {
        continue;
      }

      final dayName = orderedDayNames[dayIndex];

      final subjectId = (data['subject_id'] ?? '').toString();
      final facultyId = (data['faculty_id'] ?? '').toString();
      final roomId = (data['room_id'] ?? '').toString();
      final typ = (data['type'] ?? 'theory').toString();

      grid[dayName]![periodIndex] = {
        'subject': names.subjects[subjectId] ?? subjectId,
        'faculty': names.faculty[facultyId] ?? facultyId,
        'room': names.rooms[roomId] ?? roomId,
        'type': typ,
      };
    }

    return grid;
  }

  /// Faculty View
  static Map<String, List<Map<String, dynamic>?>> buildFacultyViewGrid({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    required List<String> orderedDayNames,
    required int periodsPerDay,
    required TimetableResolvedNames names,
    required List<int> breakIndexes,
  }) {
    final grid = emptyGridForDays(
      orderedDayNames: orderedDayNames,
      periodsPerDay: periodsPerDay,
    );

    for (final doc in docs) {
      final data = doc.data();

      final dayIndex =
          parseDayIndex(data['day'], orderedDayNames.length);

      final parsedPeriodIndex =
          parsePeriodIndex(data['period'], periodsPerDay);

      if (dayIndex == null || parsedPeriodIndex == null) {
        continue;
      }

      int periodIndex = parsedPeriodIndex;

      for (final breakIndex in breakIndexes) {
        if (periodIndex >= breakIndex) {
          periodIndex++;
        }
      }

      if (periodIndex >= periodsPerDay) {
        continue;
      }

      final dayName = orderedDayNames[dayIndex];

      final subjectId = (data['subject_id'] ?? '').toString();
      final programId = (data['program_id'] ?? '').toString();
      final roomId = (data['room_id'] ?? '').toString();
      final typ = (data['type'] ?? 'theory').toString();

      grid[dayName]![periodIndex] = {
        'subject': names.subjects[subjectId] ?? subjectId,
        'program': names.programs[programId] ?? programId,
        'room': names.rooms[roomId] ?? roomId,
        'type': typ,
      };
    }

    return grid;
  }
}