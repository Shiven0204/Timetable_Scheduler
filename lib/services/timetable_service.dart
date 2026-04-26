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
    return _db.collection('Programs').get().then((s) => s.docs);
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _fetchSubjects() {
    return _db.collection('Subjects').get().then((s) => s.docs);
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _fetchMappings() {
    return _db.collection('Mappings').get().then((s) => s.docs);
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _fetchRooms() async {
    for (final name in const ['Rooms', 'Room', 'rooms']) {
      final snap = await _db.collection(name).get();
      if (snap.docs.isNotEmpty) {
        return snap.docs;
      }
    }
    return [];
  }

  Future<Map<String, int>> _fetchConfig() async {
    for (final candidate in const [
      {'collection': 'config', 'doc': 'timetable'},
      {'collection': 'Config', 'doc': 'timetable'},
      {'collection': 'timetable_config', 'doc': 'default'},
    ]) {
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
    return {'working_days': 5, 'periods': 6};
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
