import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as dev;

class TimetableService {
  TimetableService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const List<String> _programCollections = ['programs', 'Programs'];
  static const List<String> _subjectCollections = ['subjects', 'Subjects'];
  static const List<String> _mappingCollections = ['mappings', 'Mappings'];
  static const List<String> _roomCollections = ['rooms', 'Rooms', 'Room'];
  static const List<Map<String, String>> _configCandidates = [
    {'collection': 'config', 'doc': 'timetable'},
    {'collection': 'Config', 'doc': 'timetable'},
    {'collection': 'timetable_config', 'doc': 'default'},
  ];

  Future<List<Map<String, dynamic>>> getAllPrograms() async {
    try {
      final docs = await _getDocsFromCandidates(_programCollections);
      return docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList(growable: false);
    } catch (e, st) {
      dev.log('getAllPrograms failed', error: e, stackTrace: st);
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getSubjectsByProgram(
    String programId,
  ) async {
    if (programId.isEmpty) {
      return [];
    }
    try {
      final docs = await _getDocsFromCandidates(_subjectCollections);
      return docs
          .where((doc) => (doc.data()['program_id'] ?? '') == programId)
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList(growable: false);
    } catch (e, st) {
      dev.log('getSubjectsByProgram failed', error: e, stackTrace: st);
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getMappings() async {
    try {
      final docs = await _getDocsFromCandidates(_mappingCollections);
      return docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList(growable: false);
    } catch (e, st) {
      dev.log('getMappings failed', error: e, stackTrace: st);
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getRooms() async {
    try {
      final docs = await _getDocsFromCandidates(_roomCollections);
      return docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList(growable: false);
    } catch (e, st) {
      dev.log('getRooms failed', error: e, stackTrace: st);
      return [];
    }
  }

  Future<Map<String, dynamic>> getConfig() async {
    try {
      for (final candidate in _configCandidates) {
        final doc = await _db
            .collection(candidate['collection']!)
            .doc(candidate['doc']!)
            .get();
        if (doc.exists) {
          final data = doc.data() ?? {};
          return {
            'working_days_per_week':
                (data['working_days_per_week'] as num?)?.toInt() ??
                    (data['working_days'] as num?)?.toInt() ??
                    5,
            'periods_per_day':
                (data['periods_per_day'] as num?)?.toInt() ??
                    (data['periods'] as num?)?.toInt() ??
                    6,
            'duration_per_period':
                (data['duration_per_period'] as num?)?.toInt() ?? 50,
            'max_lectures_per_day':
                (data['max_lectures_per_day'] as num?)?.toInt() ?? 4,
          };
        }
      }
    } catch (e, st) {
      dev.log('getConfig failed', error: e, stackTrace: st);
    }
    return {
      'working_days_per_week': 5,
      'periods_per_day': 6,
      'duration_per_period': 50,
      'max_lectures_per_day': 4,
    };
  }

  Future<Map<String, dynamic>> createEmptyTimetableGrid() async {
    try {
      final config = await getConfig();
      final programs = await getAllPrograms();

      final workingDays = (config['working_days_per_week'] as int?) ?? 5;
      final periodsPerDay = (config['periods_per_day'] as int?) ?? 6;
      final dayNames = _buildDayNames(workingDays);

      final timetable = <String, dynamic>{};

      for (final program in programs) {
        final programId = (program['id'] ?? '').toString();
        if (programId.isEmpty) {
          continue;
        }

        final dayGrid = <String, List<dynamic>>{};
        for (final day in dayNames) {
          dayGrid[day] = List<dynamic>.filled(periodsPerDay, null);
        }
        timetable[programId] = dayGrid;
      }

      _logEmptyGrid(timetable, dayNames, periodsPerDay);
      return timetable;
    } catch (e, st) {
      dev.log('createEmptyTimetableGrid failed', error: e, stackTrace: st);
      return {};
    }
  }

  Future<Map<String, dynamic>> prepareTimetableData() async {
    final timetableData = <String, dynamic>{};

    try {
      final programs = await getAllPrograms();
      final mappings = await getMappings();
      final rooms = await getRooms();
      final config = await getConfig();
      final mappingBySubject = _buildSubjectFacultyMap(mappings);

      for (final program in programs) {
        final programId = (program['id'] ?? '').toString();
        if (programId.isEmpty) {
          continue;
        }

        final subjects = await getSubjectsByProgram(programId);
        if (subjects.isEmpty) {
          dev.log(
            'Warning: Program $programId has no subjects',
            name: 'TimetableService',
          );
        }

        final facultyMap = <String, String>{};
        for (final subject in subjects) {
          final subjectId = (subject['id'] ?? '').toString();
          if (subjectId.isEmpty) {
            continue;
          }

          final facultyId = mappingBySubject[subjectId];
          if (facultyId == null || facultyId.isEmpty) {
            dev.log(
              'Warning: Subject $subjectId has no faculty mapping',
              name: 'TimetableService',
            );
            continue;
          }
          facultyMap[subjectId] = facultyId;
        }

        timetableData[programId] = {
          'subjects': subjects,
          'facultyMap': facultyMap,
        };
      }

      final prepared = {
        'programs': timetableData,
        'rooms': rooms,
        'config': config,
      };
      _logPreparedData(prepared);
      return prepared;
    } catch (e, st) {
      dev.log('prepareTimetableData failed', error: e, stackTrace: st);
      return {
        'programs': <String, dynamic>{},
        'rooms': <Map<String, dynamic>>[],
        'config': await getConfig(),
      };
    }
  }

  Future<void> generateTimetable() async {
    final programs = await _fetchPrograms();
    final subjects = await _fetchSubjects();
    final mappings = await _fetchMappings();
    final rooms = await _fetchRooms();
    final config = await _fetchConfig();

    if (programs.isEmpty || rooms.isEmpty) {
      throw Exception('Missing programs or rooms');
    }

    final facultySchedule = <String, Map<int, Set<int>>>{};
    final roomSchedule = <String, Map<int, Set<int>>>{};
    final rowsToWrite = <Map<String, dynamic>>[];

    final days = config['working_days']!;
    final periods = config['periods']!;

    for (final program in programs) {
      final programId = program.id;
      final programSubjects = subjects
          .where((s) => (s.data()['program_id'] ?? '') == programId)
          .toList();

      if (programSubjects.isEmpty) {
        continue;
      }

      final tasks = _buildTasks(programSubjects);
      final labTasks = tasks.where((t) => t.isLab).toList();
      final theoryTasks = tasks.where((t) => !t.isLab).toList();

      final grid = _createEmptyGrid(days: days, periods: periods);

      for (final task in labTasks) {
        final ok = _placeLab(
          task: task,
          days: days,
          periods: periods,
          grid: grid,
          mappings: mappings,
          rooms: rooms,
          facultySchedule: facultySchedule,
          roomSchedule: roomSchedule,
        );
        if (!ok) {
          throw Exception('Unable to generate timetable (lab placement failed)');
        }
      }

      for (final task in theoryTasks) {
        final ok = _placeTheory(
          task: task,
          days: days,
          periods: periods,
          grid: grid,
          mappings: mappings,
          rooms: rooms,
          facultySchedule: facultySchedule,
          roomSchedule: roomSchedule,
        );
        if (!ok) {
          throw Exception(
            'Unable to generate timetable (theory placement failed)',
          );
        }
      }

      for (var day = 0; day < days; day++) {
        for (var period = 0; period < periods; period++) {
          final slot = grid[day]![period];
          if (slot.subjectId.isEmpty) {
            continue;
          }
          rowsToWrite.add({
            'program_id': programId,
            'day': day,
            'period': period,
            'subject_id': slot.subjectId,
            'faculty_id': slot.facultyId,
            'room_id': slot.roomId,
            'created_at': FieldValue.serverTimestamp(),
          });
        }
      }
    }

    if (rowsToWrite.isEmpty) {
      throw Exception('No timetable rows generated');
    }

    await _saveTimetable(rowsToWrite);
  }

  List<_Task> _buildTasks(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> subjects,
      ) {
    final tasks = <_Task>[];
    for (final subject in subjects) {
      final data = subject.data();
      final credits = (data['credits'] as num?)?.toInt() ?? 0;
      final isLab = data['is_lab'] == true;
      final count = credits;
      for (var i = 0; i < count; i++) {
        tasks.add(_Task(subjectId: subject.id, isLab: isLab));
      }
    }
    return tasks;
  }

  Map<int, List<_Slot>> _createEmptyGrid({
    required int days,
    required int periods,
  }) {
    final grid = <int, List<_Slot>>{};
    for (var d = 0; d < days; d++) {
      grid[d] = List.generate(periods, (_) => const _Slot.empty());
    }
    return grid;
  }

  bool _placeLab({
    required _Task task,
    required int days,
    required int periods,
    required Map<int, List<_Slot>> grid,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> mappings,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> rooms,
    required Map<String, Map<int, Set<int>>> facultySchedule,
    required Map<String, Map<int, Set<int>>> roomSchedule,
  }) {
    final mapping = _findMapping(mappings, task.subjectId);
    if (mapping == null) return false;

    final facultyId = mapping['faculty_id'] as String? ?? '';
    final roomId = rooms.first.id;
    if (facultyId.isEmpty) return false;

    for (var day = 0; day < days; day++) {
      for (var period = 0; period < periods - 1; period++) {
        if (!grid[day]![period].isEmpty || !grid[day]![period + 1].isEmpty) {
          continue;
        }
        if (_isBusy(facultySchedule, facultyId, day, period) ||
            _isBusy(facultySchedule, facultyId, day, period + 1)) {
          continue;
        }
        if (_isBusy(roomSchedule, roomId, day, period) ||
            _isBusy(roomSchedule, roomId, day, period + 1)) {
          continue;
        }

        grid[day]![period] = _Slot(
          subjectId: task.subjectId,
          facultyId: facultyId,
          roomId: roomId,
        );
        grid[day]![period + 1] = _Slot(
          subjectId: task.subjectId,
          facultyId: facultyId,
          roomId: roomId,
        );

        _markBusy(facultySchedule, facultyId, day, period);
        _markBusy(facultySchedule, facultyId, day, period + 1);
        _markBusy(roomSchedule, roomId, day, period);
        _markBusy(roomSchedule, roomId, day, period + 1);
        return true;
      }
    }
    return false;
  }

  bool _placeTheory({
    required _Task task,
    required int days,
    required int periods,
    required Map<int, List<_Slot>> grid,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> mappings,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> rooms,
    required Map<String, Map<int, Set<int>>> facultySchedule,
    required Map<String, Map<int, Set<int>>> roomSchedule,
  }) {
    final mapping = _findMapping(mappings, task.subjectId);
    if (mapping == null) return false;

    final facultyId = mapping['faculty_id'] as String? ?? '';
    final roomId = rooms.first.id;
    if (facultyId.isEmpty) return false;

    for (var day = 0; day < days; day++) {
      for (var period = 0; period < periods; period++) {
        if (!grid[day]![period].isEmpty) continue;
        if (_isBusy(facultySchedule, facultyId, day, period)) continue;
        if (_isBusy(roomSchedule, roomId, day, period)) continue;

        grid[day]![period] = _Slot(
          subjectId: task.subjectId,
          facultyId: facultyId,
          roomId: roomId,
        );

        _markBusy(facultySchedule, facultyId, day, period);
        _markBusy(roomSchedule, roomId, day, period);
        return true;
      }
    }
    return false;
  }

  Map<String, dynamic>? _findMapping(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> mappings,
      String subjectId,
      ) {
    for (final m in mappings) {
      final data = m.data();
      if ((data['subject_id'] ?? '') == subjectId) {
        return data;
      }
    }
    return null;
  }

  bool _isBusy(
      Map<String, Map<int, Set<int>>> schedule,
      String id,
      int day,
      int period,
      ) {
    return schedule[id]?[day]?.contains(period) == true;
  }

  void _markBusy(
      Map<String, Map<int, Set<int>>> schedule,
      String id,
      int day,
      int period,
      ) {
    schedule.putIfAbsent(id, () => <int, Set<int>>{});
    schedule[id]!.putIfAbsent(day, () => <int>{});
    schedule[id]![day]!.add(period);
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _fetchPrograms() {
    return _getDocsFromCandidates(_programCollections);
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _fetchSubjects() {
    return _getDocsFromCandidates(_subjectCollections);
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _fetchMappings() {
    return _getDocsFromCandidates(_mappingCollections);
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _fetchRooms() async {
    return _getDocsFromCandidates(_roomCollections);
  }

  Future<Map<String, int>> _fetchConfig() async {
    final config = await getConfig();
    return {
      'working_days': (config['working_days_per_week'] as int?) ?? 5,
      'periods': (config['periods_per_day'] as int?) ?? 6,
    };
  }

  List<String> _buildDayNames(int workingDays) {
    const baseDays = <String>[
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
    ];
    if (workingDays <= 0) {
      return baseDays;
    }
    if (workingDays <= baseDays.length) {
      return baseDays.sublist(0, workingDays);
    }

    final extended = List<String>.from(baseDays);
    const extraDays = ['Saturday', 'Sunday'];
    for (var i = 0; i < workingDays - baseDays.length; i++) {
      extended.add(extraDays[i % extraDays.length]);
    }
    return extended;
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _getDocsFromCandidates(
    List<String> collections,
  ) async {
    for (final collection in collections) {
      try {
        final snap = await _db.collection(collection).get();
        if (snap.docs.isNotEmpty) {
          return snap.docs;
        }
      } catch (e, st) {
        dev.log(
          'Collection fetch failed: $collection',
          error: e,
          stackTrace: st,
          name: 'TimetableService',
        );
      }
    }
    return [];
  }

  Map<String, String> _buildSubjectFacultyMap(List<Map<String, dynamic>> mappings) {
    final subjectFacultyMap = <String, String>{};
    for (final mapping in mappings) {
      final subjectId = (mapping['subject_id'] ?? '').toString();
      final facultyId = (mapping['faculty_id'] ?? '').toString();
      if (subjectId.isEmpty || facultyId.isEmpty) {
        continue;
      }

      if (subjectFacultyMap.containsKey(subjectId) &&
          subjectFacultyMap[subjectId] != facultyId) {
        dev.log(
          'Warning: Multiple faculty mappings found for subject $subjectId. Using first mapping.',
          name: 'TimetableService',
        );
        continue;
      }
      subjectFacultyMap[subjectId] = facultyId;
    }
    return subjectFacultyMap;
  }

  void _logPreparedData(Map<String, dynamic> preparedData) {
    final programs = (preparedData['programs'] as Map<String, dynamic>? ?? {});
    final rooms = (preparedData['rooms'] as List<dynamic>? ?? []);
    final config = (preparedData['config'] as Map<String, dynamic>? ?? {});

    dev.log('----- Timetable Data Prepared -----', name: 'TimetableService');
    dev.log('Programs: ${programs.length}', name: 'TimetableService');
    for (final entry in programs.entries) {
      final data = entry.value as Map<String, dynamic>? ?? {};
      final subjects = (data['subjects'] as List<dynamic>? ?? []);
      final facultyMap = (data['facultyMap'] as Map<String, dynamic>? ?? {});
      dev.log(
        'Program ${entry.key} -> subjects: ${subjects.length}, mapped: ${facultyMap.length}',
        name: 'TimetableService',
      );
    }
    dev.log('Rooms: ${rooms.length}', name: 'TimetableService');
    dev.log('Config: $config', name: 'TimetableService');
    dev.log('----------------------------------', name: 'TimetableService');
  }

  void _logEmptyGrid(
    Map<String, dynamic> timetable,
    List<String> days,
    int periodsPerDay,
  ) {
    dev.log('----- Empty Timetable Grid -----', name: 'TimetableService');
    dev.log('Programs: ${timetable.length}', name: 'TimetableService');
    dev.log('Days: ${days.join(', ')}', name: 'TimetableService');
    dev.log('Periods per day: $periodsPerDay', name: 'TimetableService');

    for (final entry in timetable.entries) {
      final dayGrid = entry.value as Map<String, dynamic>? ?? {};
      dev.log('Program ${entry.key}', name: 'TimetableService');
      for (final day in days) {
        final slots = (dayGrid[day] as List<dynamic>? ?? []);
        dev.log('  $day -> ${slots.length} slots: $slots', name: 'TimetableService');
      }
    }

    dev.log('-------------------------------', name: 'TimetableService');
  }

  Future<void> _saveTimetable(List<Map<String, dynamic>> rows) async {
    final existing = await _db.collection('timetable').get();
    if (existing.docs.isNotEmpty) {
      final deleteBatch = _db.batch();
      for (final doc in existing.docs) {
        deleteBatch.delete(doc.reference);
      }
      await deleteBatch.commit();
    }

    final batch = _db.batch();
    for (final row in rows) {
      batch.set(_db.collection('timetable').doc(), row);
    }
    await batch.commit();
  }
}

class _Task {
  const _Task({required this.subjectId, required this.isLab});
  final String subjectId;
  final bool isLab;
}

class _Slot {
  const _Slot({
    required this.subjectId,
    required this.facultyId,
    required this.roomId,
  });

  const _Slot.empty()
      : subjectId = '',
        facultyId = '',
        roomId = '';

  final String subjectId;
  final String facultyId;
  final String roomId;

  bool get isEmpty => subjectId.isEmpty;
}
