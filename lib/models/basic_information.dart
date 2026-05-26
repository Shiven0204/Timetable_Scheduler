import 'package:timetable_scheduler/models/academic_session.dart';
import 'package:timetable_scheduler/models/schedule_slot.dart';

/// Timetable-level configuration: info, session, bell schedule, working days.
class BasicInformation {
  BasicInformation({
    this.timetableName = '',
    this.description = '',
    this.scheduleType = ScheduleType.weekly,
    this.cycleWeeks = 3,
    this.scheduleMode = ScheduleMode.uniform,
    this.workingDays = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
    this.periods = const [],
    this.breaks = const [],
    this.daySchedules = const {},
    AcademicSession? academicSession,
  }) : academicSession = academicSession ?? AcademicSession();

  static const allWeekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  final String timetableName;
  final String description;
  final AcademicSession academicSession;
  final ScheduleType scheduleType;
  final int cycleWeeks;
  final ScheduleMode scheduleMode;
  final List<String> workingDays;
  final List<ScheduleSlot> periods;
  final List<ScheduleSlot> breaks;
  /// When [scheduleMode] is custom: day key → {periods, breaks}.
  final Map<String, DaySchedule> daySchedules;

  Map<String, dynamic> toMap() => {
        'timetable_name': timetableName.trim(),
        'description': description.trim(),
        'academic_session': academicSession.toMap(),
        'schedule_type': scheduleType.name,
        'cycle_weeks': cycleWeeks,
        'schedule_mode': scheduleMode == ScheduleMode.customDay
            ? 'custom_day'
            : 'uniform',
        'working_days': List<String>.from(workingDays),
        'periods': periods.map((e) => e.toMap()).toList(),
        'breaks': breaks.map((e) => e.toMap()).toList(),
        'day_schedules': daySchedules.map(
          (key, value) => MapEntry(key, value.toMap()),
        ),
      };

  factory BasicInformation.fromMap(Map<String, dynamic> map) {
    final periodsRaw = map['periods'] as List<dynamic>? ?? [];
    final breaksRaw = map['breaks'] as List<dynamic>? ?? [];
    final dayRaw = map['day_schedules'] as Map<String, dynamic>? ?? {};

    return BasicInformation(
      timetableName: (map['timetable_name'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      academicSession: AcademicSession.fromMap(
        map['academic_session'] as Map<String, dynamic>?,
      ),
      scheduleType: ScheduleTypeX.fromString(map['schedule_type']),
      cycleWeeks: (map['cycle_weeks'] as num?)?.toInt() ?? 3,
      scheduleMode: ScheduleModeX.fromString(map['schedule_mode']),
      workingDays: (map['working_days'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
      periods: periodsRaw
          .whereType<Map<String, dynamic>>()
          .map(ScheduleSlot.fromMap)
          .toList(),
      breaks: breaksRaw
          .whereType<Map<String, dynamic>>()
          .map(ScheduleSlot.fromMap)
          .toList(),
      daySchedules: dayRaw.map(
        (key, value) => MapEntry(
          key,
          DaySchedule.fromMap(value as Map<String, dynamic>? ?? {}),
        ),
      ),
    );
  }

  BasicInformation copyWith({
    String? timetableName,
    String? description,
    AcademicSession? academicSession,
    ScheduleType? scheduleType,
    int? cycleWeeks,
    ScheduleMode? scheduleMode,
    List<String>? workingDays,
    List<ScheduleSlot>? periods,
    List<ScheduleSlot>? breaks,
    Map<String, DaySchedule>? daySchedules,
  }) {
    return BasicInformation(
      timetableName: timetableName ?? this.timetableName,
      description: description ?? this.description,
      academicSession: academicSession ?? this.academicSession,
      scheduleType: scheduleType ?? this.scheduleType,
      cycleWeeks: cycleWeeks ?? this.cycleWeeks,
      scheduleMode: scheduleMode ?? this.scheduleMode,
      workingDays: workingDays ?? List<String>.from(this.workingDays),
      periods: periods ?? List<ScheduleSlot>.from(this.periods),
      breaks: breaks ?? List<ScheduleSlot>.from(this.breaks),
      daySchedules: daySchedules ?? Map<String, DaySchedule>.from(this.daySchedules),
    );
  }
}

enum ScheduleType { weekly, fortnightly, custom }

extension ScheduleTypeX on ScheduleType {
  static ScheduleType fromString(Object? raw) {
    final s = (raw ?? 'weekly').toString().toLowerCase();
    if (s == 'fortnightly') return ScheduleType.fortnightly;
    if (s == 'custom') return ScheduleType.custom;
    return ScheduleType.weekly;
  }

  String get label {
    switch (this) {
      case ScheduleType.weekly:
        return 'Weekly';
      case ScheduleType.fortnightly:
        return 'Fortnightly';
      case ScheduleType.custom:
        return 'Custom Cycle';
    }
  }

  String get description {
    switch (this) {
      case ScheduleType.weekly:
        return 'Schedule repeats every week';
      case ScheduleType.fortnightly:
        return 'Schedule repeats every 2 weeks';
      case ScheduleType.custom:
        return 'Schedule repeats after custom number of weeks';
    }
  }
}

enum ScheduleMode { uniform, customDay }

extension ScheduleModeX on ScheduleMode {
  static ScheduleMode fromString(Object? raw) {
    final s = (raw ?? 'uniform').toString().toLowerCase();
    if (s == 'custom_day' || s == 'customday') return ScheduleMode.customDay;
    return ScheduleMode.uniform;
  }

  String get label {
    switch (this) {
      case ScheduleMode.uniform:
        return 'Uniform Schedule';
      case ScheduleMode.customDay:
        return 'Custom Day Schedule';
    }
  }

  String get description {
    switch (this) {
      case ScheduleMode.uniform:
        return 'Same lectures every working day';
      case ScheduleMode.customDay:
        return 'Different lectures for different days';
    }
  }
}

class DaySchedule {
  DaySchedule({this.periods = const [], this.breaks = const []});

  final List<ScheduleSlot> periods;
  final List<ScheduleSlot> breaks;

  Map<String, dynamic> toMap() => {
        'periods': periods.map((e) => e.toMap()).toList(),
        'breaks': breaks.map((e) => e.toMap()).toList(),
      };

  factory DaySchedule.fromMap(Map<String, dynamic> map) {
    final p = map['periods'] as List<dynamic>? ?? [];
    final b = map['breaks'] as List<dynamic>? ?? [];
    return DaySchedule(
      periods: p
          .whereType<Map<String, dynamic>>()
          .map(ScheduleSlot.fromMap)
          .toList(),
      breaks: b
          .whereType<Map<String, dynamic>>()
          .map(ScheduleSlot.fromMap)
          .toList(),
    );
  }

  DaySchedule copyWith({
    List<ScheduleSlot>? periods,
    List<ScheduleSlot>? breaks,
  }) {
    return DaySchedule(
      periods: periods ?? List<ScheduleSlot>.from(this.periods),
      breaks: breaks ?? List<ScheduleSlot>.from(this.breaks),
    );
  }
}
