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

  Future<Map<String, dynamic>> scheduleLabs(
    Map<String, dynamic> timetable,
    Map<String, dynamic> timetableData,
  ) async {
    try {
      final programsData =
          (timetableData['programs'] as Map<String, dynamic>? ?? {});
      final rooms = (timetableData['rooms'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);

      final labRooms = rooms.where(_isLabRoom).toList(growable: false);
      if (labRooms.isEmpty) {
        dev.log('No lab rooms found. Cannot schedule labs.', name: 'TimetableService');
        return timetable;
      }

      final facultySchedule = <String, Map<String, Set<int>>>{};
      final roomSchedule = <String, Map<String, Set<int>>>{};

      for (final programEntry in programsData.entries) {
        final programId = programEntry.key;
        final programInfo =
            (programEntry.value as Map<String, dynamic>? ?? <String, dynamic>{});
        final subjects = (programInfo['subjects'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .toList(growable: false);
        final facultyMap = (programInfo['facultyMap'] as Map<String, dynamic>? ?? {})
            .map((key, value) => MapEntry(key, value.toString()));

        final labSubjects = subjects
            .where((subject) => subject['is_lab'] == true)
            .toList(growable: false);

        final programGrid =
            (timetable[programId] as Map<String, dynamic>? ?? <String, dynamic>{});
        if (programGrid.isEmpty || labSubjects.isEmpty) {
          continue;
        }

        for (final subject in labSubjects) {
          final subjectId = (subject['id'] ?? '').toString();
          final facultyId = (facultyMap[subjectId] ?? '').toString();
          if (subjectId.isEmpty || facultyId.isEmpty) {
            continue;
          }

          _tryPlaceLabForProgram(
            programGrid: programGrid,
            subjectId: subjectId,
            facultyId: facultyId,
            labRooms: labRooms,
            facultySchedule: facultySchedule,
            roomSchedule: roomSchedule,
          );
        }
      }

      _logLabSchedulePreview(timetable);
      return timetable;
    } catch (e, st) {
      dev.log('scheduleLabs failed', error: e, stackTrace: st);
      return timetable;
    }
  }

  Future<Map<String, dynamic>> scheduleLabsFromPreparedData() async {
    final timetableData = await prepareTimetableData();
    final emptyGrid = await createEmptyTimetableGrid();
    return scheduleLabs(emptyGrid, timetableData);
  }

  Future<Map<String, dynamic>> scheduleTheorySubjects(
    Map<String, dynamic> timetable,
    Map<String, dynamic> timetableData,
  ) async {
    try {
      final programsData =
          (timetableData['programs'] as Map<String, dynamic>? ?? {});
      final rooms = (timetableData['rooms'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
      final classroomRooms =
          rooms.where((room) => !_isLabRoom(room)).toList(growable: false);

      if (classroomRooms.isEmpty) {
        dev.log(
          'No classroom rooms found. Theory scheduling skipped.',
          name: 'TimetableService',
        );
        return timetable;
      }

      final facultySchedule = <String, Map<String, Set<int>>>{};
      final roomSchedule = <String, Map<String, Set<int>>>{};
      _buildOccupiedSchedulesFromTimetable(
        timetable: timetable,
        facultySchedule: facultySchedule,
        roomSchedule: roomSchedule,
      );

      final assignmentStats = <String, Map<String, int>>{};

      for (final programEntry in programsData.entries) {
        final programId = programEntry.key;
        final programInfo =
            (programEntry.value as Map<String, dynamic>? ?? <String, dynamic>{});
        final subjects = (programInfo['subjects'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .toList(growable: false);
        final facultyMap =
            (programInfo['facultyMap'] as Map<String, dynamic>? ?? {})
                .map((key, value) => MapEntry(key, value.toString()));
        final programGrid =
            (timetable[programId] as Map<String, dynamic>? ?? <String, dynamic>{});
        if (programGrid.isEmpty) {
          continue;
        }

        final theorySubjects = subjects
            .where((subject) => subject['is_lab'] != true)
            .toList(growable: false);

        for (final subject in theorySubjects) {
          final subjectId = (subject['id'] ?? '').toString();
          final facultyId = (facultyMap[subjectId] ?? '').toString();
          final lecturesTarget = (subject['credits'] as num?)?.toInt() ?? 0;

          if (subjectId.isEmpty || facultyId.isEmpty || lecturesTarget <= 0) {
            continue;
          }

          var lecturesNeeded = lecturesTarget;
          while (lecturesNeeded > 0) {
            final assigned = _tryPlaceOneTheoryLecture(
              programGrid: programGrid,
              subjectId: subjectId,
              facultyId: facultyId,
              classroomRooms: classroomRooms,
              facultySchedule: facultySchedule,
              roomSchedule: roomSchedule,
            );

            if (!assigned) {
              dev.log(
                'Could not place all theory lectures for subject $subjectId in program $programId. Remaining: $lecturesNeeded',
                name: 'TimetableService',
              );
              break;
            }
            lecturesNeeded--;
          }

          assignmentStats.putIfAbsent(programId, () => <String, int>{});
          assignmentStats[programId]![subjectId] = lecturesTarget - lecturesNeeded;
        }
      }

      _logTheorySchedulePreview(timetable, assignmentStats);
      return timetable;
    } catch (e, st) {
      dev.log('scheduleTheorySubjects failed', error: e, stackTrace: st);
      return timetable;
    }
  }

  Future<Map<String, dynamic>> generateFullTimetableFromPreparedData() async {
    final timetableData = await prepareTimetableData();
    final emptyGrid = await createEmptyTimetableGrid();
    final withLabs = await scheduleLabs(emptyGrid, timetableData);
    return scheduleTheorySubjects(withLabs, timetableData);
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

  bool _isLabRoom(Map<String, dynamic> room) {
    final type = (room['room_type'] ?? room['type'] ?? '').toString().toLowerCase();
    return type.contains('lab');
  }

  bool _tryPlaceLabForProgram({
    required Map<String, dynamic> programGrid,
    required String subjectId,
    required String facultyId,
    required List<Map<String, dynamic>> labRooms,
    required Map<String, Map<String, Set<int>>> facultySchedule,
    required Map<String, Map<String, Set<int>>> roomSchedule,
  }) {
    for (final dayEntry in programGrid.entries) {
      final day = dayEntry.key;
      final slots = (dayEntry.value as List<dynamic>? ?? []);
      if (slots.length < 2) {
        continue;
      }

      for (var period = 0; period < slots.length - 1; period++) {
        final firstEmpty = slots[period] == null;
        final secondEmpty = slots[period + 1] == null;
        if (!firstEmpty || !secondEmpty) {
          continue;
        }

        final roomId = _findAvailableLabRoom(
          day: day,
          period: period,
          labRooms: labRooms,
          roomSchedule: roomSchedule,
        );
        if (roomId == null) {
          continue;
        }

        if (_isConflict(facultySchedule, facultyId, day, period) ||
            _isConflict(facultySchedule, facultyId, day, period + 1)) {
          continue;
        }

        final labSlot = {
          'subject_id': subjectId,
          'faculty_id': facultyId,
          'room_id': roomId,
          'type': 'lab',
        };

        slots[period] = Map<String, dynamic>.from(labSlot);
        slots[period + 1] = Map<String, dynamic>.from(labSlot);

        _markStringSchedule(facultySchedule, facultyId, day, period);
        _markStringSchedule(facultySchedule, facultyId, day, period + 1);
        _markStringSchedule(roomSchedule, roomId, day, period);
        _markStringSchedule(roomSchedule, roomId, day, period + 1);
        return true;
      }
    }
    return false;
  }

  String? _findAvailableLabRoom({
    required String day,
    required int period,
    required List<Map<String, dynamic>> labRooms,
    required Map<String, Map<String, Set<int>>> roomSchedule,
  }) {
    for (final room in labRooms) {
      final roomId = (room['id'] ?? '').toString();
      if (roomId.isEmpty) {
        continue;
      }
      final busyNow = _isConflict(roomSchedule, roomId, day, period);
      final busyNext = _isConflict(roomSchedule, roomId, day, period + 1);
      if (!busyNow && !busyNext) {
        return roomId;
      }
    }
    return null;
  }

  bool _isConflict(
    Map<String, Map<String, Set<int>>> schedule,
    String id,
    String day,
    int period,
  ) {
    return schedule[id]?[day]?.contains(period) == true;
  }

  void _markStringSchedule(
    Map<String, Map<String, Set<int>>> schedule,
    String id,
    String day,
    int period,
  ) {
    schedule.putIfAbsent(id, () => <String, Set<int>>{});
    schedule[id]!.putIfAbsent(day, () => <int>{});
    schedule[id]![day]!.add(period);
  }

  void _logLabSchedulePreview(Map<String, dynamic> timetable) {
    if (timetable.isEmpty) {
      dev.log('Lab scheduling preview: timetable is empty', name: 'TimetableService');
      return;
    }

    final firstProgram = timetable.entries.first;
    final programId = firstProgram.key;
    final programGrid =
        (firstProgram.value as Map<String, dynamic>? ?? <String, dynamic>{});
    dev.log('----- Lab Scheduling Preview -----', name: 'TimetableService');
    dev.log('Program: $programId', name: 'TimetableService');

    for (final dayEntry in programGrid.entries) {
      final day = dayEntry.key;
      final slots = (dayEntry.value as List<dynamic>? ?? []);
      dev.log('$day -> $slots', name: 'TimetableService');
    }

    dev.log('-------------------------------', name: 'TimetableService');
  }

  void _buildOccupiedSchedulesFromTimetable({
    required Map<String, dynamic> timetable,
    required Map<String, Map<String, Set<int>>> facultySchedule,
    required Map<String, Map<String, Set<int>>> roomSchedule,
  }) {
    for (final programEntry in timetable.entries) {
      final dayGrid =
          (programEntry.value as Map<String, dynamic>? ?? <String, dynamic>{});
      for (final dayEntry in dayGrid.entries) {
        final day = dayEntry.key;
        final slots = (dayEntry.value as List<dynamic>? ?? []);
        for (var period = 0; period < slots.length; period++) {
          final slot = slots[period];
          if (slot is! Map<String, dynamic>) {
            continue;
          }
          final facultyId = (slot['faculty_id'] ?? '').toString();
          final roomId = (slot['room_id'] ?? '').toString();
          if (facultyId.isNotEmpty) {
            _markStringSchedule(facultySchedule, facultyId, day, period);
          }
          if (roomId.isNotEmpty) {
            _markStringSchedule(roomSchedule, roomId, day, period);
          }
        }
      }
    }
  }

  bool _tryPlaceOneTheoryLecture({
    required Map<String, dynamic> programGrid,
    required String subjectId,
    required String facultyId,
    required List<Map<String, dynamic>> classroomRooms,
    required Map<String, Map<String, Set<int>>> facultySchedule,
    required Map<String, Map<String, Set<int>>> roomSchedule,
  }) {
    for (final dayEntry in programGrid.entries) {
      final day = dayEntry.key;
      final slots = (dayEntry.value as List<dynamic>? ?? []);

      if (_subjectAlreadyPlacedInDay(slots, subjectId)) {
        continue;
      }

      for (var period = 0; period < slots.length; period++) {
        if (slots[period] != null) {
          continue;
        }
        if (_isConflict(facultySchedule, facultyId, day, period)) {
          continue;
        }

        final roomId = _findAvailableClassroom(
          day: day,
          period: period,
          classroomRooms: classroomRooms,
          roomSchedule: roomSchedule,
        );
        if (roomId == null) {
          continue;
        }

        slots[period] = {
          'subject_id': subjectId,
          'faculty_id': facultyId,
          'room_id': roomId,
          'type': 'theory',
        };
        _markStringSchedule(facultySchedule, facultyId, day, period);
        _markStringSchedule(roomSchedule, roomId, day, period);
        return true;
      }
    }
    return false;
  }

  bool _subjectAlreadyPlacedInDay(List<dynamic> slots, String subjectId) {
    for (final slot in slots) {
      if (slot is Map<String, dynamic> && slot['subject_id'] == subjectId) {
        return true;
      }
    }
    return false;
  }

  String? _findAvailableClassroom({
    required String day,
    required int period,
    required List<Map<String, dynamic>> classroomRooms,
    required Map<String, Map<String, Set<int>>> roomSchedule,
  }) {
    for (final room in classroomRooms) {
      final roomId = (room['id'] ?? '').toString();
      if (roomId.isEmpty) {
        continue;
      }
      if (!_isConflict(roomSchedule, roomId, day, period)) {
        return roomId;
      }
    }
    return null;
  }

  void _logTheorySchedulePreview(
    Map<String, dynamic> timetable,
    Map<String, Map<String, int>> assignmentStats,
  ) {
    if (timetable.isEmpty) {
      dev.log(
        'Theory scheduling preview: timetable is empty',
        name: 'TimetableService',
      );
      return;
    }

    final firstProgram = timetable.entries.first;
    final programId = firstProgram.key;
    final programGrid =
        (firstProgram.value as Map<String, dynamic>? ?? <String, dynamic>{});

    dev.log('----- Theory Scheduling Preview -----', name: 'TimetableService');
    dev.log('Program: $programId', name: 'TimetableService');
    for (final dayEntry in programGrid.entries) {
      final day = dayEntry.key;
      final slots = (dayEntry.value as List<dynamic>? ?? []);
      dev.log('$day -> $slots', name: 'TimetableService');
    }

    final stats = assignmentStats[programId] ?? {};
    dev.log('Assigned lectures by subject: $stats', name: 'TimetableService');
    dev.log('-----------------------------------', name: 'TimetableService');
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
