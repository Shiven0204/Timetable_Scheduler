import 'package:flutter/material.dart';

class AddProgramScreen extends StatefulWidget {
  const AddProgramScreen({super.key});

  @override
  State<AddProgramScreen> createState() => _AddProgramScreenState();
}

class _AddProgramScreenState extends State<AddProgramScreen> {
  static const _departments = ['Tech', 'Science', 'Management'];

  final _programNameController = TextEditingController();
  final _branchController = TextEditingController();
  final _yearController = TextEditingController();
  String? _department;

  @override
  void dispose() {
    _programNameController.dispose();
    _branchController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  void _onSave() {
    final programName = _programNameController.text.trim();
    final branch = _branchController.text.trim();
    final year = _yearController.text.trim();
    final department = _department ?? '(none selected)';
    debugPrint(
      'Program: $programName | Branch: $branch | Year: $year | Department: $department',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Program'),
      ),
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
              decoration: const InputDecoration(
                labelText: 'Year',
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
                  value: _department,
                  hint: const Text('Select department'),
                  items: _departments
                      .map(
                        (d) => DropdownMenuItem(
                          value: d,
                          child: Text(d),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _department = value;
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
