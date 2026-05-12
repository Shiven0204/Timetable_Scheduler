import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:timetable_scheduler/services/database_service.dart';

/// Maps subject + faculty + program to a specific [room_id] (lab vs classroom).
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
  String? _selectedRoomId;

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
            'program_name': d['program_name'] ?? '',
            'branch_name': d['branch_name'] ?? '',
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
            'name': d['faculty_name'] ?? doc.id,
            'department_id': (d['department_id'] ?? '').toString(),
          };
        }).toList();

        _rooms = roomSnap.docs.map((doc) {
          final d = doc.data();
          return {
            'id': doc.id,
            'name': d['room_name'] ?? doc.id,
            'room_type': (d['room_type'] ?? '').toString(),
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

  bool _isLabRoomType(String roomType) {
    return roomType.toLowerCase().contains('lab');
  }

  List<Map<String, dynamic>> get _roomsForSelectedSubject {
    final sub = _currentSubject;
    if (sub == null) return [];
    final isLab = sub['is_lab'] == true;
    return _rooms.where((r) {
      final t = (r['room_type'] ?? '').toString();
      final lab = _isLabRoomType(t);
      return isLab ? lab : !lab;
    }).toList();
  }

  void _onDepartmentChanged(String? id) {
    setState(() {
      _selectedDepartmentId = id;
      _selectedProgramId = null;
      _selectedSubjectId = null;
      _selectedFacultyId = null;
      _selectedRoomId = null;
    });
  }

  void _onProgramChanged(String? id) {
    setState(() {
      _selectedProgramId = id;
      _selectedSubjectId = null;
      _selectedFacultyId = null;
      _selectedRoomId = null;
    });
  }

  void _onSubjectChanged(String? id) {
    setState(() {
      _selectedSubjectId = id;
      _selectedRoomId = null;
    });
  }

  Future<void> _onSave() async {
    if (_selectedDepartmentId == null ||
        _selectedProgramId == null ||
        _selectedSubjectId == null ||
        _selectedFacultyId == null ||
        _selectedRoomId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select department, program, subject, faculty, and room')),
      );
      return;
    }

    final roomsPick = _roomsForSelectedSubject;
    if (roomsPick.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No suitable room for this subject type. Add a Lab or Classroom room.'),
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
        roomId: _selectedRoomId!,
        departmentId: deptId.isNotEmpty ? deptId : null,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mapping saved')),
      );

      setState(() {
        _selectedSubjectId = null;
        _selectedFacultyId = null;
        _selectedRoomId = null;
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

    final roomItems = _roomsForSelectedSubject;
    final sub = _currentSubject;
    final roomHint = sub == null
        ? ''
        : (sub['is_lab'] == true ? 'Lab rooms only' : 'Classroom-type rooms only');

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
                  'Subject → Faculty → Room (per program)',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Order: Department → Program → Subject → Faculty → Room',
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
                if (roomHint.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      roomHint,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                _buildDropdown(
                  label: 'Room',
                  value: _selectedRoomId,
                  items: roomItems,
                  displayKey: 'name',
                  onChanged: (val) => setState(() => _selectedRoomId = val),
                  enabled: _selectedSubjectId != null && roomItems.isNotEmpty,
                ),
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
