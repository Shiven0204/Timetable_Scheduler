import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:timetable_scheduler/services/database_service.dart';
import 'package:timetable_scheduler/utils/short_name_generator.dart';
import 'package:timetable_scheduler/widgets/institute_form_card.dart';

class AddProgramScreen extends StatefulWidget {
  const AddProgramScreen({
    this.embeddedInDialog = false,
    super.key,
  });

  final bool embeddedInDialog;

  @override
  State<AddProgramScreen> createState() => AddProgramScreenState();
}

class AddProgramScreenState extends State<AddProgramScreen> {
  final _nameController = TextEditingController();
  final _shortNameController = TextEditingController();
  final _studentCountController = TextEditingController();

  final DatabaseService _dbService = DatabaseService();

  bool _shortNameEdited = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onNameChanged);
  }

  void _onNameChanged() {
    if (_shortNameEdited) return;
    final generated = ShortNameGenerator.generate(_nameController.text);
    _shortNameController.value = TextEditingValue(
      text: generated,
      selection: TextSelection.collapsed(offset: generated.length),
    );
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _shortNameController.dispose();
    _studentCountController.dispose();
    super.dispose();
  }

  Future<bool> submit() async {
    final name = _nameController.text.trim();
    final shortName = _shortNameController.text.trim().toUpperCase();
    final countText = _studentCountController.text.trim();

    if (name.isEmpty) {
      _showSnack('Program name is required');
      return false;
    }
    if (shortName.isEmpty) {
      _showSnack('Short name is required');
      return false;
    }

    int? studentCount;
    if (countText.isNotEmpty) {
      studentCount = int.tryParse(countText);
      if (studentCount == null || studentCount < 0) {
        _showSnack('Enter a valid student count');
        return false;
      }
    }

    setState(() => _saving = true);
    try {
      await _dbService.saveProgram(
        name: name,
        shortName: shortName,
        studentCount: studentCount,
      );
      if (!mounted) return false;
      if (!widget.embeddedInDialog) {
        _showSnack('Program saved');
      }
      _nameController.clear();
      _shortNameController.clear();
      _studentCountController.clear();
      setState(() => _shortNameEdited = false);
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
      title: 'Program details',
      subtitle: 'Short name is generated automatically',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: instituteInputDecoration(
              'Program Name *',
              hint: 'e.g. Computer Science Engineering',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _shortNameController,
            textCapitalization: TextCapitalization.characters,
            onChanged: (_) => _shortNameEdited = true,
            decoration: instituteInputDecoration(
              'Short Name *',
              hint: 'e.g. CSE',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _studentCountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: instituteInputDecoration('Student Count'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embeddedInDialog) {
      return _buildForm();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Add Program')),
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
