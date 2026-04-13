import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timetable_scheduler/services/database_service.dart';

class AddProgramScreen extends StatefulWidget {
  const AddProgramScreen({super.key});

  @override
  State<AddProgramScreen> createState() => _AddProgramScreenState();
}

class _AddProgramScreenState extends State<AddProgramScreen> {
  final _programNameController = TextEditingController();
  final _branchController = TextEditingController();
  final _yearController = TextEditingController();

  final DatabaseService _dbService = DatabaseService();

  String? _selectedDepartmentId;
  List<Map<String, dynamic>> _departments = [];

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('Department')
        .get();

    setState(() {
      _departments = snapshot.docs.map((doc) {
        return {
          'id': doc.id, // 🔥 doc.id
          'name': doc['dept_name'],
        };
      }).toList();
    });
  }

  @override
  void dispose() {
    _programNameController.dispose();
    _branchController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  void _onSave() async {
    final programName = _programNameController.text.trim();
    final branch = _branchController.text.trim();
    final yearText = _yearController.text.trim();

    if (programName.isEmpty ||
        branch.isEmpty ||
        yearText.isEmpty ||
        _selectedDepartmentId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Fill all fields')));
      return;
    }

    try {
      int year = int.parse(yearText);

      await _dbService.saveProgram(
        programName: programName,
        branchName: branch,
        year: year,
        departmentId: _selectedDepartmentId!, // 🔥 mapping
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Program saved')));

      _programNameController.clear();
      _branchController.clear();
      _yearController.clear();

      setState(() {
        _selectedDepartmentId = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Program')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _programNameController,
              decoration: const InputDecoration(
                labelText: 'Program Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _branchController,
              decoration: const InputDecoration(
                labelText: 'Branch',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _yearController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Year',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // 🔥 SAME UI STYLE (just dynamic data)
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Department',
                border: OutlineInputBorder(),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedDepartmentId,
                  hint: const Text('Select department'),
                  items: _departments.map<DropdownMenuItem<String>>((d) {
                    return DropdownMenuItem<String>(
                      value: d['id'], // doc.id
                      child: Text(d['name']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDepartmentId = value;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _onSave,
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}