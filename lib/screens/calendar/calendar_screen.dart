import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:timetable_scheduler/services/timetable_firestore_helpers.dart';
import 'package:timetable_scheduler/services/timetable_name_resolver.dart';
import 'package:timetable_scheduler/services/timetable_service.dart';
import 'package:timetable_scheduler/widgets/timetable_grid.dart';

/// Weekly grid for a selected program (same Firestore shape as student view).
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final TimetableService _timetableService = TimetableService();
  final TimetableNameResolver _nameResolver = TimetableNameResolver();

  List<String> _dayNames = List<String>.from(_defaultDays);
  List<Map<String, dynamic>> _programs = [];
  String? _selectedProgramId;
  bool _loadingPrograms = true;
  bool _loadingTimetable = false;
  String? _errorMessage;
  int _periodsPerDay = 6;

  Map<String, List<Map<String, dynamic>?>> _grid = {};

  static const List<String> _defaultDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
  ];

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
      final programsSnapshot = await _firstNonEmpty(['programs', 'Programs']);
      if (!mounted) return;

      final programs = programsSnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();

      final dayNames = await _timetableService.getWorkingDayNames();
      if (!mounted) return;

      final configDoc = await _db.collection('config').doc('timetable').get();
      if (!mounted) return;

      final periods = (configDoc.data()?['periods_per_day'] as num?)?.toInt() ??
          (configDoc.data()?['periods'] as num?)?.toInt() ??
          6;

      setState(() {
        _programs = programs;
        _dayNames = dayNames.isNotEmpty ? dayNames : _defaultDays;
        _periodsPerDay = periods;
        _grid = TimetableFirestoreHelpers.emptyGridForDays(
          orderedDayNames: _dayNames,
          periodsPerDay: periods,
        );
        _selectedProgramId =
            programs.isNotEmpty ? programs.first['id'] as String : null;
      });

      if (_selectedProgramId != null) {
        await _loadTimetableForProgram(_selectedProgramId!);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load programs. Check your connection.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingPrograms = false;
        });
      }
    }
  }

  Future<void> _loadTimetableForProgram(String programId) async {
    setState(() {
      _loadingTimetable = true;
      _errorMessage = null;
      _grid = TimetableFirestoreHelpers.emptyGridForDays(
        orderedDayNames: _dayNames,
        periodsPerDay: _periodsPerDay,
      );
    });

    try {
      final timetableSnapshot = await _db
          .collection('timetable')
          .where('program_id', isEqualTo: programId)
          .get();

      if (!mounted) return;

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

      final names = await _nameResolver.resolve(
        subjectIds: subjectIds,
        facultyIds: facultyIds,
        roomIds: roomIds,
      );

      if (!mounted) return;

      final nextGrid = TimetableFirestoreHelpers.buildProgramViewGrid(
        docs: timetableSnapshot.docs,
        orderedDayNames: _dayNames,
        periodsPerDay: _periodsPerDay,
        names: names,
      );

      setState(() {
        _grid = nextGrid;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load timetable from Firestore.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingTimetable = false;
        });
      }
    }
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

  bool get _isGridEmpty => TimetableFirestoreHelpers.isGridEmpty(_grid);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Subject · Faculty · Room',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedProgramId,
                  decoration: const InputDecoration(
                    labelText: 'Program',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: _programs
                      .map(
                        (program) => DropdownMenuItem<String>(
                          value: program['id'] as String,
                          child: Text(
                            (program['program_name'] ??
                                    program['name'] ??
                                    program['id'])
                                .toString(),
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
                          await _loadTimetableForProgram(value);
                        },
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_loadingPrograms || _loadingTimetable)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_errorMessage != null)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              )
            else if (_selectedProgramId == null)
              const Expanded(
                child: Center(child: Text('No programs available')),
              )
            else if (_isGridEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    'No timetable for this program yet.',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ),
              )
            else
              Expanded(
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: SingleChildScrollView(
                      child: TimetableGrid(
                        days: _dayNames,
                        periodsPerDay: _periodsPerDay,
                        grid: _grid,
                        mode: TimetableGridMode.programView,
                      ),
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
