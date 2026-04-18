import 'package:cloud_firestore/cloud_firestore.dart';

class TimetableService {
  TimetableService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Future<void> generateTimetable() async {
    final programs = await _fetchPrograms();
    final subjects = await _fetchSubjects();
    final mappings = await _fetchMappings();
    final rooms = await _fetchRooms();
    final config = await _fetchConfig();

    if (programs.isEmpty || rooms.isEmpty) {
      throw Exception('Missing programs or rooms');
    }

    final Map<String, Map<int, Set<int>>> facultySchedule = {};
    final Map<String, Map<int, Set<int>>> roomSchedule = {};

    final List<Map<String, dynamic>> writeRows = [];
    final timetable = <String, Map<int, List<Map<String, String>>>>{};

    for (final program in programs) {
      final programId = program.id;
      final programSubjects = subjects
          .where((s) => (s.data()['program_id'] ?? '') == programId)
          .toList();

      if (programSubjects.isEmpty) {
        continue;
      }

      final tasks = _buildTasks(programSubjects);
      final labs = tasks.where((t) => t['is_lab'] == true).toList();
      final theories = tasks.where((t) => t['is_lab'] != true).toList();

      final days = config['working_days'] as int;
      final periods = config['periods'] as int;
      final grid = _createEmptyGrid(days: days, periods: periods);

      final usedSlots = <String>{};

      for (final task in labs) {
        final assigned = _assignLabTask(
          task: task,
          days: days,
          periods: periods,
          grid: grid,
          mappings: mappings,
          rooms: rooms,
          facultySchedule: facultySchedule,
          roomSchedule: roomSchedule,
          usedSlots: usedSlots,
        );
        if (!assigned) {
          throw Exception('Unable to place all lab slots');
        }
      }

      for (final task in theories) {
        final assigned = _assignTheoryTask(
          task: task,
          days: days,
          periods: periods,
          grid: grid,
          mappings: mappings,
          rooms: rooms,
          facultySchedule: facultySchedule,
          roomSchedule: roomSchedule,
          usedSlots: usedSlots,
        );
        if (!assigned) {
          throw Exception('Unable to place all theory slots');
        }
      }

      timetable[programId] = grid;

      for (var day = 0; day < days; day++) {
        final slots = grid[day] ?? [];
        for (var period = 0; period < slots.length; period++) {
          final slot = slots[period];
          final subjectId = slot['subject_id'] ?? '';
          if (subjectId.isEmpty) {
            continue;
          }

          writeRows.add({
            'program_id': programId,
            'day': day,
            'period': period,
            'subject_id': subjectId,
            'faculty_id': slot['faculty_id'],
            'room_id': slot['room_id'],
            'created_at': FieldValue.serverTimestamp(),
          });
        }
      }
    }

    if (writeRows.isEmpty) {
      throw Exception('No timetable rows generated');
    }

    await _saveTimetable(writeRows);
  }

  List<Map<String, dynamic>> _buildTasks(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> subjects,
  ) {
    final tasks = <Map<String, dynamic>>[];

    for (final subject in subjects) {
      final data = subject.data();
      final subjectId = subject.id;
      final credits = (data['credits'] as num?)?.toInt() ?? 0;
      final isLab = data['is_lab'] == true;
      final taskCount = isLab ? credits : credits;

      for (var i = 0; i < taskCount; i++) {
        tasks.add({
          'subject_id': subjectId,
          'is_lab': isLab,
          'needs_double_slot': isLab,
        });
      }
    }

    return tasks;
  }

  Map<int, List<Map<String, String>>> _createEmptyGrid({
    required int days,
    required int periods,
  }) {
    final grid = <int, List<Map<String, String>>>{};
    for (var d = 0; d < days; d++) {
      grid[d] = List.generate(periods, (_) => <String, String>{});
    }
    return grid;
  }

  bool _assignLabTask({
    required Map<String, dynamic> task,
    required int days,
    required int periods,
    required Map<int, List<Map<String, String>>> grid,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> mappings,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> rooms,
    required Map<String, Map<int, Set<int>>> facultySchedule,
    required Map<String, Map<int, Set<int>>> roomSchedule,
    required Set<String> usedSlots,
  }) {
    final match = _findMappingForSubject(
      mappings: mappings,
      subjectId: task['subject_id'] as String,
    );
    if (match == null) {
      return false;
    }

    final facultyId = match['faculty_id'] as String;
    final roomId = _pickRoom(rooms) ?? '';
    if (roomId.isEmpty) {
      return false;
    }

    for (var day = 0; day < days; day++) {
      for (var period = 0; period < periods - 1; period++) {
        final keyA = '$day-$period';
        final keyB = '$day-${period + 1}';
        if (usedSlots.contains(keyA) || usedSlots.contains(keyB)) {
          continue;
        }
        if (_isFacultyBusy(facultySchedule, facultyId, day, period) ||
            _isFacultyBusy(facultySchedule, facultyId, day, period + 1)) {
          continue;
        }
        if (_isRoomBusy(roomSchedule, roomId, day, period) ||
            _isRoomBusy(roomSchedule, roomId, day, period + 1)) {
          continue;
        }

        grid[day]![period] = {
          'subject_id': task['subject_id'] as String,
          'faculty_id': facultyId,
          'room_id': roomId,
        };
        grid[day]![period + 1] = {
          'subject_id': task['subject_id'] as String,
          'faculty_id': facultyId,
          'room_id': roomId,
        };

        usedSlots.add(keyA);
        usedSlots.add(keyB);
        _markBusy(facultySchedule, facultyId, day, period);
        _markBusy(facultySchedule, facultyId, day, period + 1);
        _markBusy(roomSchedule, roomId, day, period);
        _markBusy(roomSchedule, roomId, day, period + 1);
        return true;
      }
    }
    return false;
  }

  bool _assignTheoryTask({
    required Map<String, dynamic> task,
    required int days,
    required int periods,
    required Map<int, List<Map<String, String>>> grid,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> mappings,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> rooms,
    required Map<String, Map<int, Set<int>>> facultySchedule,
    required Map<String, Map<int, Set<int>>> roomSchedule,
    required Set<String> usedSlots,
  }) {
    final match = _findMappingForSubject(
      mappings: mappings,
      subjectId: task['subject_id'] as String,
    );
    if (match == null) {
      return false;
    }

    final facultyId = match['faculty_id'] as String;
    final roomId = _pickRoom(rooms) ?? '';
    if (roomId.isEmpty) {
      return false;
    }

    for (var day = 0; day < days; day++) {
      for (var period = 0; period < periods; period++) {
        final key = '$day-$period';
        if (usedSlots.contains(key)) {
          continue;
        }
        if (_isFacultyBusy(facultySchedule, facultyId, day, period)) {
          continue;
        }
        if (_isRoomBusy(roomSchedule, roomId, day, period)) {
          continue;
        }

        grid[day]![period] = {
          'subject_id': task['subject_id'] as String,
          'faculty_id': facultyId,
          'room_id': roomId,
        };

        usedSlots.add(key);
        _markBusy(facultySchedule, facultyId, day, period);
        _markBusy(roomSchedule, roomId, day, period);
        return true;
      }
    }
    return false;
  }

  Map<String, dynamic>? _findMappingForSubject({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> mappings,
    required String subjectId,
  }) {
    for (final m in mappings) {
      final data = m.data();
      if ((data['subject_id'] ?? '') == subjectId) {
        return data;
      }
    }
    return null;
  }

  String? _pickRoom(List<QueryDocumentSnapshot<Map<String, dynamic>>> rooms) {
    if (rooms.isEmpty) {
      return null;
    }
    return rooms.first.id;
  }

  bool _isFacultyBusy(
    Map<String, Map<int, Set<int>>> schedule,
    String facultyId,
    int day,
    int period,
  ) {
    return schedule[facultyId]?[day]?.contains(period) == true;
  }

  bool _isRoomBusy(
    Map<String, Map<int, Set<int>>> schedule,
    String roomId,
    int day,
    int period,
  ) {
    return schedule[roomId]?[day]?.contains(period) == true;
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
    return _db.collection('Programs').get().then((s) => s.docs);
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _fetchSubjects() {
    return _db.collection('Subjects').get().then((s) => s.docs);
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _fetchMappings() {
    return _db.collection('Mappings').get().then((s) => s.docs);
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _fetchRooms() async {
    final roomCandidates = ['Rooms', 'Room', 'rooms'];
    for (final name in roomCandidates) {
      final snap = await _db.collection(name).get();
      if (snap.docs.isNotEmpty) {
        return snap.docs;
      }
    }
    return [];
  }

  Future<Map<String, int>> _fetchConfig() async {
    final defaults = {'working_days': 5, 'periods': 6};
    final configCandidates = [
      {'collection': 'config', 'doc': 'timetable'},
      {'collection': 'Config', 'doc': 'timetable'},
      {'collection': 'timetable_config', 'doc': 'default'},
    ];

    for (final candidate in configCandidates) {
      final doc = await _db
          .collection(candidate['collection']!)
          .doc(candidate['doc']!)
          .get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        return {
          'working_days': (data['working_days'] as num?)?.toInt() ?? 5,
          'periods': (data['periods'] as num?)?.toInt() ?? 6,
        };
      }
    }

    return defaults;
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

    final writeBatch = _db.batch();
    for (final row in rows) {
      final ref = _db.collection('timetable').doc();
      writeBatch.set(ref, row);
    }
    await writeBatch.commit();
  }
}

