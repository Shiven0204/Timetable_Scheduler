import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:timetable_scheduler/services/database_service.dart';
import 'package:timetable_scheduler/utils/room_type_utils.dart';

/// Maps each subject (per program) to faculty + **theory** room (`room_type: classroom`) + optional **lab** room (`room_type: lab`).
///
/// When `is_lab` is true on the subject, it means **theory + one weekly lab block** (not lab-only):
/// pick a classroom for theory and a lab room for the 2-period lab session.
class AddMappingScreen extends StatefulWidget {
  const AddMappingScreen({super.key});

  @override
  State<AddMappingScreen> createState() => _AddMappingScreenState();
}

class _AddMappingScreenState extends State<AddMappingScreen> {
  final DatabaseService _dbService = DatabaseService();

  String? _selectedDepartmentId;
  String? _selectedProgramId;
  String? _selectedSubjectId;
  String? _selectedFacultyId;
  String? _selectedTheoryRoomId;
  String? _selectedLabRoomId;

  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _programs = [];
  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _faculties = [];
  List<Map<String, dynamic>> _rooms = [];

  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final db = FirebaseFirestore.instance;

      final deptSnap = await db.collection('Department').get();
      final progSnap = await db.collection('Programs').get();
      final subSnap = await db.collection('Subjects').get();
      final facSnap = await db.collection('Faculty').get();
      final roomSnap = await db.collection('Rooms').get();

      if (!mounted) return;

      setState(() {
        _departments = deptSnap.docs.map((doc) {
          return {
            'id': doc.id,
            'name': doc['dept_name'] ?? doc.id,
          };
        }).toList();

        _programs = progSnap.docs.map((doc) {
          final d = doc.data();
          return {
            'id': doc.id,
            'program_name': d['program_name'] ?? d['name'] ?? '',
            'branch_name': d['branch_name'] ?? d['short_name'] ?? '',
            'department_id': (d['department_id'] ?? '').toString(),
          };
        }).toList();

        _subjects = subSnap.docs.map((doc) {
          final d = doc.data();
          return {
            'id': doc.id,
            'name': d['subject_name'] ?? doc.id,
            'program_id': (d['program_id'] ?? '').toString(),
            'is_lab': d['is_lab'] == true,
          };
        }).toList();

        _faculties = facSnap.docs.map((doc) {
          final d = doc.data();
          return {
            'id': doc.id,
            'name': d['faculty_name'] ?? d['full_name'] ?? doc.id,
            'department_id': (d['department_id'] ?? '').toString(),
          };
        }).toList();

        _rooms = roomSnap.docs.map((doc) {
          final d = doc.data();
          return {
            'id': doc.id,
            'name': d['room_name'] ?? d['name'] ?? doc.id,
            'room_type': (d['room_type'] ?? d['type'] ?? '').toString(),
          };
        }).toList();
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadError = 'Could not load data: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _programsForDepartment {
    if (_selectedDepartmentId == null) return [];
    return _programs
        .where((p) => (p['department_id'] ?? '') == _selectedDepartmentId)
        .toList();
  }

  List<Map<String, dynamic>> get _subjectsForProgram {
    if (_selectedProgramId == null) return [];
    return _subjects
        .where((s) => (s['program_id'] ?? '') == _selectedProgramId)
        .toList();
  }

  Map<String, dynamic>? get _currentProgram {
    for (final p in _programs) {
      if (p['id'] == _selectedProgramId) return p;
    }
    return null;
  }

  Map<String, dynamic>? get _currentSubject {
    for (final s in _subjectsForProgram) {
      if (s['id'] == _selectedSubjectId) return s;
    }
    return null;
  }

  List<Map<String, dynamic>> get _facultiesForProgramDepartment {
    final prog = _currentProgram;
    final deptId = (prog?['department_id'] ?? '').toString();
    if (deptId.isEmpty) {
      return _faculties;
    }
    return _faculties
        .where((f) => (f['department_id'] ?? '').toString() == deptId)
        .toList();
  }

  /// Theory slots: only rooms with canonical `classroom` type.
  List<Map<String, dynamic>> get _classroomRooms {
    return _rooms.where((r) {
      final t = r['room_type'] ?? r['type'];
      return RoomTypeUtils.isClassroom(t);
    }).toList();
  }

  /// Lab slots: only rooms with canonical `lab` type.
  List<Map<String, dynamic>> get _labRoomsOnly {
    return _rooms.where((r) {
      final t = r['room_type'] ?? r['type'];
      return RoomTypeUtils.isLab(t);
    }).toList();
  }

  void _onDepartmentChanged(String? id) {
    setState(() {
      _selectedDepartmentId = id;
      _selectedProgramId = null;
      _selectedSubjectId = null;
      _selectedFacultyId = null;
      _selectedTheoryRoomId = null;
      _selectedLabRoomId = null;
    });
  }

  void _onProgramChanged(String? id) {
    setState(() {
      _selectedProgramId = id;
      _selectedSubjectId = null;
      _selectedFacultyId = null;
      _selectedTheoryRoomId = null;
      _selectedLabRoomId = null;
    });
  }

  void _onSubjectChanged(String? id) {
    setState(() {
      _selectedSubjectId = id;
      _selectedTheoryRoomId = null;
      _selectedLabRoomId = null;
    });
  }

  Future<void> _onSave() async {
    if (_selectedDepartmentId == null ||
        _selectedProgramId == null ||
        _selectedSubjectId == null ||
        _selectedFacultyId == null ||
        _selectedTheoryRoomId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Select department, program, subject, faculty, and theory room',
          ),
        ),
      );
      return;
    }

    final sub = _currentSubject;
    final isLabCourse = sub?['is_lab'] == true;

    if (isLabCourse) {
      if (_selectedLabRoomId == null || _selectedLabRoomId!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This subject includes a lab: select a lab room as well.',
            ),
          ),
        );
        return;
      }
    }

    if (_classroomRooms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Add at least one room with room type classroom first.',
          ),
        ),
      );
      return;
    }

    if (isLabCourse && _labRoomsOnly.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Add at least one room with room type lab for theory+lab subjects.',
          ),
        ),
      );
      return;
    }

    final prog = _currentProgram;
    final deptId = (prog?['department_id'] ?? _selectedDepartmentId ?? '').toString();

    try {
      await _dbService.saveMapping(
        facultyId: _selectedFacultyId!,
        subjectId: _selectedSubjectId!,
        programId: _selectedProgramId!,
        theoryRoomId: _selectedTheoryRoomId!,
        labRoomId: isLabCourse ? _selectedLabRoomId : null,
        departmentId: deptId.isNotEmpty ? deptId : null,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mapping saved')),
      );

      setState(() {
        _selectedSubjectId = null;
        _selectedFacultyId = null;
        _selectedTheoryRoomId = null;
        _selectedLabRoomId = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<Map<String, dynamic>> items,
    required String displayKey,
    required ValueChanged<String?> onChanged,
    bool enabled = true,
  }) {
    return InputDecorator(
      decoration: _decoration(label),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          hint: Text('Select $label'),
          items: items.map<DropdownMenuItem<String>>((item) {
            return DropdownMenuItem<String>(
              value: item['id'] as String,
              child: Text(
                item[displayKey].toString(),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: enabled ? onChanged : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Add Mapping')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Add Mapping')),
        body: Center(child: Text(_loadError!)),
      );
    }

    final sub = _currentSubject;
    final isLabCourse = sub?['is_lab'] == true;
    final theoryItems = _classroomRooms;
    final labItems = _labRoomsOnly;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Mapping')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Faculty + rooms (per program)',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  isLabCourse
                      ? 'This subject has theory lectures and one weekly lab block. Pick a classroom and a lab room.'
                      : 'Theory-only subject: pick a classroom.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                _buildDropdown(
                  label: 'Department',
                  value: _selectedDepartmentId,
                  items: _departments,
                  displayKey: 'name',
                  onChanged: _onDepartmentChanged,
                ),
                const SizedBox(height: 16),
                _buildDropdown(
                  label: 'Program',
                  value: _selectedProgramId,
                  items: _programsForDepartment,
                  displayKey: 'program_name',
                  onChanged: _onProgramChanged,
                  enabled: _selectedDepartmentId != null,
                ),
                const SizedBox(height: 16),
                _buildDropdown(
                  label: 'Subject',
                  value: _selectedSubjectId,
                  items: _subjectsForProgram,
                  displayKey: 'name',
                  onChanged: _onSubjectChanged,
                  enabled: _selectedProgramId != null,
                ),
                const SizedBox(height: 16),
                _buildDropdown(
                  label: 'Faculty',
                  value: _selectedFacultyId,
                  items: _facultiesForProgramDepartment,
                  displayKey: 'name',
                  onChanged: (val) => setState(() => _selectedFacultyId = val),
                  enabled: _selectedProgramId != null,
                ),
                const SizedBox(height: 16),
                _buildDropdown(
                  label: 'Theory room (classroom)',
                  value: _selectedTheoryRoomId,
                  items: theoryItems,
                  displayKey: 'name',
                  onChanged: (val) => setState(() => _selectedTheoryRoomId = val),
                  enabled: _selectedSubjectId != null && theoryItems.isNotEmpty,
                ),
                if (isLabCourse) ...[
                  const SizedBox(height: 16),
                  _buildDropdown(
                    label: 'Lab room',
                    value: _selectedLabRoomId,
                    items: labItems,
                    displayKey: 'name',
                    onChanged: (val) => setState(() => _selectedLabRoomId = val),
                    enabled: _selectedSubjectId != null && labItems.isNotEmpty,
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _onSave,
                    child: const Text('Save Mapping'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
