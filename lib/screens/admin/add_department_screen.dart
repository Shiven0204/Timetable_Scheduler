import 'package:flutter/material.dart';
// ignore: unused_import
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timetable_scheduler/services/database_service.dart';

class AddDepartmentScreen extends StatefulWidget {
  const AddDepartmentScreen({super.key});

  @override
  State<AddDepartmentScreen> createState() => _AddDepartmentScreenState();
}

class _AddDepartmentScreenState extends State<AddDepartmentScreen> {
  final TextEditingController _nameController = TextEditingController();
  final DatabaseService _dbService = DatabaseService();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onSave() async {
    final name = _nameController.text.trim();

    // Validation
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter department name')),
      );
      return;
    }

    try {
      // Save to Firebase
      await _dbService.saveDepartment(name);

      // Success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Department saved')),
      );

      // Clear input
      _nameController.clear();

    } catch (e) {
      // Error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Department'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Department Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
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