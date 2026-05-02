import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timetable_scheduler/services/database_service.dart';

class AddSubjectScreen extends StatefulWidget {
  const AddSubjectScreen({super.key});

  @override
  State<AddSubjectScreen> createState() => _AddSubjectScreenState();
}

class _AddSubjectScreenState extends State<AddSubjectScreen> {

  final _subjectNameController = TextEditingController();
  final _creditsController = TextEditingController();

  final DatabaseService _dbService = DatabaseService();

  bool _isLab = false;

  String? _selectedProgramId;
  List<Map<String, dynamic>> _programs = [];

  @override
  void initState() {
    super.initState();
    _loadPrograms();
  }

  Future<void> _loadPrograms() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('Programs')
        .get();

    setState(() {
      _programs = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'program_name': doc['program_name'],
          'branch_name': doc['branch_name'],
        };
      }).toList();
    });
  }

  @override
  void dispose() {
    _subjectNameController.dispose();
    _creditsController.dispose();
    super.dispose();
  }

  void _onSave() async {
    final subjectName = _subjectNameController.text.trim();
    final creditsText = _creditsController.text.trim();

    if (subjectName.isEmpty ||
        creditsText.isEmpty ||
        _selectedProgramId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill all fields')),
      );
      return;
    }

    try {
      int credits = int.tryParse(creditsText) ?? 0;

      await _dbService.saveSubject(
        subjectName: subjectName,
        credits: credits,
        isLab: _isLab,
        programId: _selectedProgramId!,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subject saved')),
      );

      _subjectNameController.clear();
      _creditsController.clear();

      setState(() {
        _isLab = false;
        _selectedProgramId = null;
      });

    } catch (e) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Subject'),
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
                  'Subject Details',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _subjectNameController,
                  decoration: _decoration('Subject Name'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _creditsController,
                  keyboardType: TextInputType.number,
                  decoration: _decoration('Credits'),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Is Lab'),
                  value: _isLab,
                  onChanged: (value) {
                    setState(() {
                      _isLab = value;
                    });
                  },
                ),
                const SizedBox(height: 8),
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
                      onChanged: (value) {
                        setState(() {
                          _selectedProgramId = value;
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