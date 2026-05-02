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
          'id': doc.id,
          'name': doc['dept_name'],
        };
      }).toList();
    });
  }

  @override
  void dispose() {
    _programNameController.dispose();
    _branchController.dispose();
    super.dispose();
  }

  void _onSave() async {
    final programName = _programNameController.text.trim();
    final branch = _branchController.text.trim();

    if (programName.isEmpty ||
        branch.isEmpty ||
        _selectedDepartmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill all fields')),
      );
      return;
    }

    try {
      await _dbService.saveProgram(
        programName: programName,
        branchName: branch,
        departmentId: _selectedDepartmentId!,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Program saved')),
      );

      _programNameController.clear();
      _branchController.clear();

      setState(() {
        _selectedDepartmentId = null;
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Program'),
      ),
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
                  'Program Details',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _programNameController,
                  decoration: const InputDecoration(
                    labelText: 'Program Name (include year)',
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
                          value: d['id'],
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
        ),
      ),
    );
  }
}