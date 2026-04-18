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

  String? _selectedFacultyId;
  String? _selectedSubjectId;
  String? _selectedProgramId;

  List<Map<String, dynamic>> _faculties = [];
  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _programs = [];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
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
        _selectedSubjectId == null ||
        _selectedProgramId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select all fields')));
      return;
    }

    try {
      await _dbService.saveMapping(
        facultyId: _selectedFacultyId!,
        subjectId: _selectedSubjectId!,
        programId: _selectedProgramId!,
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Mapping saved')));

      setState(() {
        _selectedFacultyId = null;
        _selectedSubjectId = null;
        _selectedProgramId = null;
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

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<Map<String, dynamic>> items,
    required String displayKey,
    required Function(String?) onChanged,
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
              value: item['id'],
              child: Text(item[displayKey]),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
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
            _buildDropdown(
              label: 'Faculty',
              value: _selectedFacultyId,
              items: _faculties,
              displayKey: 'name',
              onChanged: (val) => setState(() => _selectedFacultyId = val),
            ),

            const SizedBox(height: 16),

            _buildDropdown(
              label: 'Subject',
              value: _selectedSubjectId,
              items: _subjects,
              displayKey: 'name',
              onChanged: (val) => setState(() => _selectedSubjectId = val),
            ),

            const SizedBox(height: 16),

            InputDecorator(
              decoration: _decoration('Program'),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedProgramId,
                  hint: const Text('Select program'),
                  items: _programs.map<DropdownMenuItem<String>>((p) {
                    return DropdownMenuItem<String>(
                      value: p['id'],
                      child: Text("${p['program_name']} - ${p['branch_name']}"),
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
              ),
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
    );
  }
}
