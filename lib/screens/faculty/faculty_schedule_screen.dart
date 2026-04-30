import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FacultyScheduleScreen extends StatefulWidget {
  const FacultyScheduleScreen({super.key});

  @override
  State<FacultyScheduleScreen> createState() => _FacultyScheduleScreenState();
}

class _FacultyScheduleScreenState extends State<FacultyScheduleScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
  ];

  List<Map<String, dynamic>> _faculties = [];
  String? _selectedFacultyId;
  bool _loadingFaculties = true;
  bool _loadingSchedule = false;
  String? _errorMessage;
  int _periodsPerDay = 6;

  Map<String, List<Map<String, dynamic>?>> _grid = {
    for (final day in _days) day: List<Map<String, dynamic>?>.filled(6, null),
  };

  @override
  void initState() {
    super.initState();
    _loadFaculties();
  }

  Future<void> _loadFaculties() async {
    setState(() {
      _loadingFaculties = true;
      _errorMessage = null;
    });

    try {
      final facultySnapshot = await _firstNonEmpty(['faculty', 'Faculty']);
      final faculties = facultySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();

      final configDoc = await _db.collection('config').doc('timetable').get();
      final periods = (configDoc.data()?['periods_per_day'] as num?)?.toInt() ??
          (configDoc.data()?['periods'] as num?)?.toInt() ??
          6;

      setState(() {
        _faculties = faculties;
        _periodsPerDay = periods;
        _grid = _emptyGrid(periods);
        _selectedFacultyId =
            faculties.isNotEmpty ? faculties.first['id'] as String : null;
      });

      if (_selectedFacultyId != null) {
        await getTimetableByFaculty(_selectedFacultyId!);
      }
    } catch (_) {
      setState(() {
        _errorMessage = 'Failed to load faculties';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingFaculties = false;
        });
      }
    }
  }

  Future<void> getTimetableByFaculty(String facultyId) async {
    setState(() {
      _loadingSchedule = true;
      _errorMessage = null;
      _grid = _emptyGrid(_periodsPerDay);
    });

    try {
      final timetableSnapshot = await _db
          .collection('timetable')
          .where('faculty_id', isEqualTo: facultyId)
          .get();

      if (timetableSnapshot.docs.isEmpty) {
        setState(() {
          _loadingSchedule = false;
        });
        return;
      }

      final subjectIds = <String>{};
      final programIds = <String>{};
      final roomIds = <String>{};

      for (final doc in timetableSnapshot.docs) {
        final data = doc.data();
        final subjectId = (data['subject_id'] ?? '').toString();
        final programId = (data['program_id'] ?? '').toString();
        final roomId = (data['room_id'] ?? '').toString();
        if (subjectId.isNotEmpty) subjectIds.add(subjectId);
        if (programId.isNotEmpty) programIds.add(programId);
        if (roomId.isNotEmpty) roomIds.add(roomId);
      }

      final subjectMap = await _fetchNameMapByIds(
        ids: subjectIds,
        collectionCandidates: ['subjects', 'Subjects'],
        nameFieldCandidates: ['subject_name', 'name'],
      );
      final programMap = await _fetchNameMapByIds(
        ids: programIds,
        collectionCandidates: ['programs', 'Programs'],
        nameFieldCandidates: ['program_name', 'name'],
      );
      final roomMap = await _fetchNameMapByIds(
        ids: roomIds,
        collectionCandidates: ['rooms', 'Rooms', 'Room'],
        nameFieldCandidates: ['room_name', 'name'],
      );

      final nextGrid = _emptyGrid(_periodsPerDay);
      for (final doc in timetableSnapshot.docs) {
        final data = doc.data();
        final dayIndex = _parseInt(data['day']);
        final periodIndex = _parseInt(data['period']);

        if (dayIndex == null ||
            periodIndex == null ||
            dayIndex < 0 ||
            dayIndex >= _days.length ||
            periodIndex < 0 ||
            periodIndex >= _periodsPerDay) {
          continue;
        }

        final dayName = _days[dayIndex];
        final subjectId = (data['subject_id'] ?? '').toString();
        final programId = (data['program_id'] ?? '').toString();
        final roomId = (data['room_id'] ?? '').toString();

        nextGrid[dayName]![periodIndex] = {
          'subject': subjectMap[subjectId] ?? subjectId,
          'program': programMap[programId] ?? programId,
          'room': roomMap[roomId] ?? roomId,
        };
      }

      setState(() {
        _grid = nextGrid;
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Failed to load schedule';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingSchedule = false;
        });
      }
    }
  }

  int? _parseInt(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse('$value');
  }

  Map<String, List<Map<String, dynamic>?>> _emptyGrid(int periods) {
    return {
      for (final day in _days)
        day: List<Map<String, dynamic>?>.filled(periods, null),
    };
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _firstNonEmpty(
    List<String> collections,
  ) async {
    QuerySnapshot<Map<String, dynamic>>? fallback;
    for (final collection in collections) {
      final snapshot = await _db.collection(collection).get();
      fallback ??= snapshot;
      if (snapshot.docs.isNotEmpty) {
        return snapshot;
      }
    }
    return fallback ?? await _db.collection(collections.first).get();
  }

  Future<Map<String, String>> _fetchNameMapByIds({
    required Set<String> ids,
    required List<String> collectionCandidates,
    required List<String> nameFieldCandidates,
  }) async {
    if (ids.isEmpty) return {};

    for (final collection in collectionCandidates) {
      final result = <String, String>{};
      var foundAny = false;

      for (final id in ids) {
        final doc = await _db.collection(collection).doc(id).get();
        if (!doc.exists) continue;
        foundAny = true;
        final data = doc.data() ?? {};
        String name = id;
        for (final field in nameFieldCandidates) {
          final value = data[field];
          if (value != null && value.toString().trim().isNotEmpty) {
            name = value.toString();
            break;
          }
        }
        result[id] = name;
      }

      if (foundAny) return result;
    }

    return {for (final id in ids) id: id};
  }

  bool get _isGridEmpty {
    for (final day in _days) {
      final row = _grid[day] ?? [];
      if (row.any((cell) => cell != null)) return false;
    }
    return true;
  }

  Widget _buildCell(String text, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isHeader ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildSlotCell(Map<String, dynamic>? slot) {
    if (slot == null) return _buildCell('-');

    final subject = (slot['subject'] ?? '-').toString();
    final program = (slot['program'] ?? '').toString();
    final room = (slot['room'] ?? '').toString();

    return Padding(
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            subject,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
          if (program.isNotEmpty)
            Text(
              program,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10),
            ),
          if (room.isNotEmpty)
            Text(
              room,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10),
            ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    final borderColor = Colors.grey.shade400;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        defaultColumnWidth: const FixedColumnWidth(120),
        border: TableBorder.all(color: borderColor, width: 1),
        children: [
          TableRow(
            decoration: const BoxDecoration(color: Color(0xFFF2F2F2)),
            children: [
              _buildCell('Day', isHeader: true),
              for (var p = 0; p < _periodsPerDay; p++)
                _buildCell('P${p + 1}', isHeader: true),
            ],
          ),
          for (final day in _days)
            TableRow(
              children: [
                _buildCell(day, isHeader: true),
                for (var p = 0; p < _periodsPerDay; p++)
                  _buildSlotCell(_grid[day]![p]),
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Faculty Schedule'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedFacultyId,
              decoration: const InputDecoration(
                labelText: 'Select Faculty',
                border: OutlineInputBorder(),
              ),
              items: _faculties
                  .map(
                    (faculty) => DropdownMenuItem<String>(
                      value: faculty['id'] as String,
                      child: Text(
                        (faculty['faculty_name'] ?? faculty['id']).toString(),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: _loadingFaculties
                  ? null
                  : (value) async {
                      if (value == null) return;
                      setState(() {
                        _selectedFacultyId = value;
                      });
                      await getTimetableByFaculty(value);
                    },
            ),
            const SizedBox(height: 16),
            if (_loadingFaculties || _loadingSchedule)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              Expanded(
                child: Center(child: Text(_errorMessage!)),
              )
            else if (_selectedFacultyId == null)
              const Expanded(
                child: Center(child: Text('No faculty available')),
              )
            else if (_isGridEmpty)
              const Expanded(
                child: Center(child: Text('No schedule available')),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  child: _buildTable(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

