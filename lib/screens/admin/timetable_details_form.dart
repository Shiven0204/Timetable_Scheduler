import 'package:flutter/material.dart';
import 'package:timetable_scheduler/models/academic_session.dart';
import 'package:timetable_scheduler/models/basic_information.dart';
import 'package:timetable_scheduler/services/basic_information_service.dart';
import 'package:timetable_scheduler/widgets/institute_form_card.dart';

class TimetableDetailsForm extends StatefulWidget {
  const TimetableDetailsForm({
    required this.baseInfo,
    this.embeddedInDialog = false,
    super.key,
  });

  final BasicInformation baseInfo;
  final bool embeddedInDialog;

  @override
  State<TimetableDetailsForm> createState() => TimetableDetailsFormState();
}

class TimetableDetailsFormState extends State<TimetableDetailsForm> {
  final _service = BasicInformationService();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _sessionNameController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _syncFromBase(widget.baseInfo);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _sessionNameController.dispose();
    super.dispose();
  }

  void _syncFromBase(BasicInformation info) {
    _nameController.text = info.timetableName;
    _descriptionController.text = info.description;
    _sessionNameController.text = info.academicSession.sessionName;
    _startDate = info.academicSession.startDate;
    _endDate = info.academicSession.endDate;
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  String _formatDate(DateTime? d) {
    if (d == null) return 'Select date';
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  BasicInformation _buildMerged(BasicInformation current) {
    return current.copyWith(
      timetableName: _nameController.text,
      description: _descriptionController.text,
      academicSession: AcademicSession(
        sessionName: _sessionNameController.text,
        startDate: _startDate,
        endDate: _endDate,
      ),
    );
  }

  Future<bool> submit() async {
    setState(() => _saving = true);
    try {
      final current = await _service.load() ?? widget.baseInfo;
      final merged = _buildMerged(current);
      final error = BasicInformationService.validateTimetableDetails(merged);
      if (error != null) {
        _showSnack(error);
        return false;
      }
      await _service.save(merged);
      if (!mounted) return false;
      if (!widget.embeddedInDialog) {
        _showSnack('Timetable details saved');
      }
      return true;
    } catch (e) {
      if (!mounted) return false;
      _showSnack('Could not save: $e');
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildForm() {
    return InstituteFormCard(
      title: 'Timetable details',
      subtitle: 'Name, description, and academic session',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _nameController,
            decoration: instituteInputDecoration('Timetable Name *'),
            maxLength: 100,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            decoration: instituteInputDecoration(
              'Description',
              hint: 'Notes about this timetable…',
            ),
            maxLines: 3,
            maxLength: 500,
          ),
          const SizedBox(height: 20),
          Text(
            'Academic Session',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Optional — if you start, complete name, start, and end dates.',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _sessionNameController,
            decoration: instituteInputDecoration(
              'Session Name',
              hint: 'e.g. 2025–2026',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DateButton(
                  label: 'Start Date',
                  value: _formatDate(_startDate),
                  onTap: () => _pickDate(isStart: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DateButton(
                  label: 'End Date',
                  value: _formatDate(_endDate),
                  onTap: () => _pickDate(isStart: false),
                ),
              ),
            ],
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
      appBar: AppBar(title: const Text('Timetable Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildForm(),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              width: double.infinity,
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

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
        ),
        child: Text(value),
      ),
    );
  }
}
