import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ViewTimetableScreen extends StatefulWidget {
  const ViewTimetableScreen({super.key});

  @override
  State<ViewTimetableScreen> createState() => _ViewTimetableScreenState();
}

class _ViewTimetableScreenState extends State<ViewTimetableScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
  ];

  List<Map<String, dynamic>> _programs = [];
  String? _selectedProgramId;
  bool _loadingPrograms = true;
  bool _loadingTimetable = false;
  String? _errorMessage;
  int _periodsPerDay = 6;

  Map<String, List<Map<String, dynamic>?>> _grid = {
    for (final day in _days) day: List<Map<String, dynamic>?>.filled(6, null),
  };

  @override
  void initState() {
    super.initState();
    _loadPrograms();
  }

  Future<void> _loadPrograms() async {
    setState(() {
      _loadingPrograms = true;
      _errorMessage = null;
    });

    try {
      final programsSnapshot = await _firstNonEmpty([
        'programs',
        'Programs',
      ]);

      final programs = programsSnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();

      final configDoc = await _db.collection('config').doc('timetable').get();
      final periods = (configDoc.data()?['periods_per_day'] as num?)?.toInt() ??
          (configDoc.data()?['periods'] as num?)?.toInt() ??
          6;

      setState(() {
        _programs = programs;
        _periodsPerDay = periods;
        _grid = _emptyGrid(periods);
        _selectedProgramId = programs.isNotEmpty ? programs.first['id'] as String : null;
      });

      if (_selectedProgramId != null) {
        await getTimetableByProgram(_selectedProgramId!);
      }
    } catch (_) {
      setState(() {
        _errorMessage = 'Failed to load programs';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingPrograms = false;
        });
      }
    }
  }

  Future<void> getTimetableByProgram(String programId) async {
    setState(() {
      _loadingTimetable = true;
      _errorMessage = null;
      _grid = _emptyGrid(_periodsPerDay);
    });

    try {
      final timetableSnapshot = await _db
          .collection('timetable')
          .where('program_id', isEqualTo: programId)
          .get();

      if (timetableSnapshot.docs.isEmpty) {
        setState(() {
          _loadingTimetable = false;
        });
        return;
      }

      final subjectIds = <String>{};
      final facultyIds = <String>{};
      final roomIds = <String>{};

      for (final doc in timetableSnapshot.docs) {
        final data = doc.data();
        final subjectId = (data['subject_id'] ?? '').toString();
        final facultyId = (data['faculty_id'] ?? '').toString();
        final roomId = (data['room_id'] ?? '').toString();
        if (subjectId.isNotEmpty) subjectIds.add(subjectId);
        if (facultyId.isNotEmpty) facultyIds.add(facultyId);
        if (roomId.isNotEmpty) roomIds.add(roomId);
      }

      final subjectMap = await _fetchNameMapByIds(
        ids: subjectIds,
        collectionCandidates: ['subjects', 'Subjects'],
        nameFieldCandidates: ['subject_name', 'name'],
      );
      final facultyMap = await _fetchNameMapByIds(
        ids: facultyIds,
        collectionCandidates: ['faculty', 'Faculty'],
        nameFieldCandidates: ['faculty_name', 'name'],
      );
      final roomMap = await _fetchNameMapByIds(
        ids: roomIds,
        collectionCandidates: ['rooms', 'Rooms', 'Room'],
        nameFieldCandidates: ['room_name', 'name'],
      );

      final nextGrid = _emptyGrid(_periodsPerDay);
      for (final doc in timetableSnapshot.docs) {
        final data = doc.data();
        final dayValue = data['day'];
        final periodValue = data['period'];

        final dayIndex = dayValue is num ? dayValue.toInt() : int.tryParse('$dayValue');
        final periodIndex =
            periodValue is num ? periodValue.toInt() : int.tryParse('$periodValue');
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
        final facultyId = (data['faculty_id'] ?? '').toString();
        final roomId = (data['room_id'] ?? '').toString();

        nextGrid[dayName]![periodIndex] = {
          'subject': subjectMap[subjectId] ?? subjectId,
          'faculty': facultyMap[facultyId] ?? '',
          'room': roomMap[roomId] ?? '',
        };
      }

      setState(() {
        _grid = nextGrid;
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Failed to load timetable';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingTimetable = false;
        });
      }
    }
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
    if (ids.isEmpty) {
      return {};
    }

    for (final collection in collectionCandidates) {
      final result = <String, String>{};
      var foundAny = false;

      for (final id in ids) {
        final doc = await _db.collection(collection).doc(id).get();
        if (!doc.exists) {
          continue;
        }
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

      if (foundAny) {
        return result;
      }
    }
    return {for (final id in ids) id: id};
  }

  bool get _isGridEmpty {
    for (final day in _days) {
      final row = _grid[day] ?? [];
      if (row.any((cell) => cell != null)) {
        return false;
      }
    }
    return true;
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
              _cell('Day', isHeader: true),
              for (var p = 0; p < _periodsPerDay; p++) _cell('P${p + 1}', isHeader: true),
            ],
          ),
          for (final day in _days)
            TableRow(
              children: [
                _cell(day, isHeader: true),
                for (var p = 0; p < _periodsPerDay; p++) _slotCell(_grid[day]![p]),
              ],
            ),
        ],
      ),
    );
  }

  Widget _cell(String text, {bool isHeader = false}) {
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

  Widget _slotCell(Map<String, dynamic>? slot) {
    if (slot == null) {
      return _cell('-');
    }
    final subject = (slot['subject'] ?? '-').toString();
    final faculty = (slot['faculty'] ?? '').toString();
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
          if (faculty.isNotEmpty)
            Text(
              faculty,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Timetable'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weekly Student Timetable',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedProgramId,
                  decoration: const InputDecoration(
                    labelText: 'Select Program',
                    border: OutlineInputBorder(),
                  ),
                  items: _programs
                      .map(
                        (program) => DropdownMenuItem<String>(
                          value: program['id'] as String,
                          child: Text(
                            (program['program_name'] ?? program['id']).toString(),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: _loadingPrograms
                      ? null
                      : (value) async {
                          if (value == null) return;
                          setState(() {
                            _selectedProgramId = value;
                          });
                          await getTimetableByProgram(value);
                        },
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_loadingPrograms || _loadingTimetable)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              Expanded(
                child: Center(child: Text(_errorMessage!)),
              )
            else if (_selectedProgramId == null)
              const Expanded(
                child: Center(child: Text('No programs available')),
              )
            else if (_isGridEmpty)
              const Expanded(
                child: Center(child: Text('No timetable available')),
              )
            else
              Expanded(
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: SingleChildScrollView(
                      child: _buildTable(),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

