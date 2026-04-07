import 'package:flutter/material.dart';

class AddSubjectScreen extends StatefulWidget {
  const AddSubjectScreen({super.key});

  @override
  State<AddSubjectScreen> createState() => _AddSubjectScreenState();
}

class _AddSubjectScreenState extends State<AddSubjectScreen> {
  static const _programs = ['BTech CSE 1st Year', 'BCA 2nd Year'];

  final _subjectNameController = TextEditingController();
  final _creditsController = TextEditingController();
  bool _isLab = false;
  String? _program;

  @override
  void dispose() {
    _subjectNameController.dispose();
    _creditsController.dispose();
    super.dispose();
  }

  void _onSave() {
    final subjectName = _subjectNameController.text.trim();
    final credits = _creditsController.text.trim();
    final isLab = _isLab ? 'Yes' : 'No';
    final program = _program ?? '(none selected)';

    debugPrint(
      'Subject: $subjectName | Credits: $credits | Is Lab: $isLab | Program: $program',
    );
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                  value: _program,
                  hint: const Text('Select program'),
                  items: _programs
                      .map(
                        (p) => DropdownMenuItem(
                          value: p,
                          child: Text(p),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _program = value;
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

