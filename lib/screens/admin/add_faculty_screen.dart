import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timetable_scheduler/services/database_service.dart';

class AddFacultyScreen extends StatefulWidget {
  const AddFacultyScreen({super.key});

  @override
  State<AddFacultyScreen> createState() => _AddFacultyScreenState();
}

class _AddFacultyScreenState extends State<AddFacultyScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _expertiseController = TextEditingController();
  final _maxLecturesController = TextEditingController();

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
        return {'id': doc.id, 'name': doc['dept_name']};
      }).toList();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _expertiseController.dispose();
    _maxLecturesController.dispose();
    super.dispose();
  }

  void _onSave() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final expertiseText = _expertiseController.text.trim();
    final maxLecturesText = _maxLecturesController.text.trim();

    if (name.isEmpty ||
        email.isEmpty ||
        expertiseText.isEmpty ||
        maxLecturesText.isEmpty ||
        _selectedDepartmentId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Fill all fields')));
      return;
    }

    try {
      List<String> expertiseList = expertiseText
          .split(',')
          .map((e) => e.trim())
          .toList();

      int maxLectures = int.tryParse(maxLecturesText) ?? 0;

      await _dbService.saveFaculty(
        facultyName: name,
        email: email,
        expertise: expertiseList,
        maxLecturesPerDay: maxLectures,
        departmentId: _selectedDepartmentId!,
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Faculty saved')));

      _nameController.clear();
      _emailController.clear();
      _expertiseController.clear();
      _maxLecturesController.clear();

      setState(() {
        _selectedDepartmentId = null;
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
      appBar: AppBar(title: const Text('Add Faculty')),
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
                  'Faculty Details',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  decoration: _decoration('Faculty Name'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _decoration('Email'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _expertiseController,
                  decoration: _decoration('Expertise (comma separated)'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _maxLecturesController,
                  keyboardType: TextInputType.number,
                  decoration: _decoration('Max Lectures Per Day'),
                ),
                const SizedBox(height: 16),
                InputDecorator(
                  decoration: _decoration('Department'),
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
