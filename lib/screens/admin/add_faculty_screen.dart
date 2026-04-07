import 'package:flutter/material.dart';

class AddFacultyScreen extends StatefulWidget {
  const AddFacultyScreen({super.key});

  @override
  State<AddFacultyScreen> createState() => _AddFacultyScreenState();
}

class _AddFacultyScreenState extends State<AddFacultyScreen> {
  static const _departments = ['Tech', 'Science', 'Management'];

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _expertiseController = TextEditingController();
  String? _department;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _expertiseController.dispose();
    super.dispose();
  }

  void _onSave() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final expertise = _expertiseController.text.trim();
    final department = _department ?? '(none selected)';

    debugPrint(
      'Faculty: $name | Email: $email | Phone: $phone | Expertise: $expertise | Department: $department',
    );

    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _expertiseController.clear();
    setState(() {
      _department = null;
    });
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
        title: const Text('Add Faculty'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: _decoration('Phone Number'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _expertiseController,
              decoration: _decoration('Expertise (comma separated)'),
            ),
            const SizedBox(height: 16),
            InputDecorator(
              decoration: _decoration('Department'),
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

