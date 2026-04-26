import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timetable_scheduler/services/database_service.dart';

class AddMappingScreen extends StatefulWidget {
  const AddMappingScreen({super.key});

  @override
  State<AddMappingScreen> createState() => _AddMappingScreenState();
}

class _AddMappingScreenState extends State<AddMappingScreen> {
  final DatabaseService _dbService = DatabaseService();

  List<Map<String, dynamic>> _faculties = [];
  List<Map<String, dynamic>> _programs = [];
  List<Map<String, dynamic>> _subjects = [];

  String? _selectedFacultyId;
  String? _selectedProgramId;
  String? _selectedSubjectId;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  // 🔥 LOAD FACULTY + PROGRAM
  Future<void> _loadInitialData() async {
    final facultySnap = await FirebaseFirestore.instance
        .collection('Faculty')
        .get();

    final programSnap = await FirebaseFirestore.instance
        .collection('Programs')
        .get();

    setState(() {
      _faculties = facultySnap.docs.map((doc) {
        return {'id': doc.id, 'name': doc['faculty_name']};
      }).toList();

      _programs = programSnap.docs.map((doc) {
        return {
          'id': doc.id,
          'program_name': doc['program_name'],
          'branch_name': doc['branch_name'],
        };
      }).toList();

      _subjects = [];
    });
  }

  // 🔥 FILTER SUBJECTS
  Future<void> _loadSubjectsByProgram(String programId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('Subjects')
        .where('program_id', isEqualTo: programId)
        .get();

    setState(() {
      _subjects = snapshot.docs.map((doc) {
        return {'id': doc.id, 'name': doc['subject_name']};
      }).toList();
    });
  }

  void _onSave() async {
    if (_selectedFacultyId == null ||
        _selectedProgramId == null ||
        _selectedSubjectId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select all fields')));
      return;
    }

    try {
      await _dbService.saveMapping(
        facultyId: _selectedFacultyId!,
        programId: _selectedProgramId!,
        subjectId: _selectedSubjectId!,
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Mapping saved')));

      setState(() {
        _selectedFacultyId = null;
        _selectedProgramId = null;
        _selectedSubjectId = null;
        _subjects = [];
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Mapping')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Faculty
            DropdownButtonFormField<String>(
              value: _selectedFacultyId,
              hint: const Text('Select Faculty'),
              items: _faculties.map((f) {
                return DropdownMenuItem<String>(
                  value: f['id'],
                  child: Text(f['name']),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedFacultyId = val;
                });
              },
            ),

            const SizedBox(height: 16),

            // Program
            DropdownButtonFormField<String>(
              value: _selectedProgramId,
              hint: const Text('Select Program'),
              items: _programs.map((p) {
                return DropdownMenuItem<String>(
                  value: p['id'],
                  child: Text("${p['program_name']} (${p['branch_name']})"),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedProgramId = val;
                  _selectedSubjectId = null;
                  _subjects = [];
                });

                _loadSubjectsByProgram(val!);
              },
            ),

            const SizedBox(height: 16),

            // Subject
            DropdownButtonFormField<String>(
              value: _selectedSubjectId,
              hint: const Text('Select Subject'),
              items: _subjects.map((s) {
                return DropdownMenuItem<String>(
                  value: s['id'],
                  child: Text(s['name']),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedSubjectId = val;
                });
              },
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _onSave,
              child: const Text('Save Mapping'),
            ),
          ],
        ),
      ),
    );
  }
}
