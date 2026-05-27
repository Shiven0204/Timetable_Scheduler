import 'package:flutter/material.dart';
import 'package:timetable_scheduler/services/database_service.dart';
import 'package:timetable_scheduler/widgets/institute_form_card.dart';

class AddDepartmentScreen extends StatefulWidget {
  const AddDepartmentScreen({
    this.embeddedInDialog = false,
    super.key,
  });

  final bool embeddedInDialog;

  @override
  State<AddDepartmentScreen> createState() => AddDepartmentScreenState();
}

class AddDepartmentScreenState extends State<AddDepartmentScreen> {
  final TextEditingController _nameController = TextEditingController();
  final DatabaseService _dbService = DatabaseService();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// Validates, saves to Firestore, clears on success. Returns whether save succeeded.
  Future<bool> submit() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      _showSnack('Please enter department name');
      return false;
    }

    setState(() => _saving = true);
    try {
      await _dbService.saveDepartment(name);
      if (!mounted) return false;
      if (!widget.embeddedInDialog) {
        _showSnack('Department saved');
      }
      _nameController.clear();
      return true;
    } catch (e) {
      if (!mounted) return false;
      _showSnack('Error: $e');
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildForm() {
    return InstituteFormCard(
      title: 'Department details',
      child: TextField(
        controller: _nameController,
        textCapitalization: TextCapitalization.words,
        decoration: instituteInputDecoration('Department Name *'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embeddedInDialog) {
      return _buildForm();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Add Department')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildForm(),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: _saving ? null : submit,
                child: _saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('NEXT'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
