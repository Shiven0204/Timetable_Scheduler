import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:timetable_scheduler/services/database_service.dart';
import 'package:timetable_scheduler/utils/short_name_generator.dart';
import 'package:timetable_scheduler/widgets/institute_form_card.dart';

class AddFacultyScreen extends StatefulWidget {
  const AddFacultyScreen({super.key});

  @override
  State<AddFacultyScreen> createState() => _AddFacultyScreenState();
}

class _AddFacultyScreenState extends State<AddFacultyScreen> {
  final _fullNameController = TextEditingController();
  final _shortNameController = TextEditingController();
  final _maxLecturesController = TextEditingController(text: '4');
  final _emailController = TextEditingController();
  final _roleController = TextEditingController();
  final _phoneController = TextEditingController();
  final _designationController = TextEditingController();

  final DatabaseService _dbService = DatabaseService();

  static const _availabilityOptions = {
    'first_half': 'First Half',
    'second_half': 'Second Half',
    'both': 'Both',
  };

  String _availability = 'both';
  bool _shortNameEdited = false;
  bool _additionalExpanded = false;
  String? _selectedDepartmentId;
  List<Map<String, dynamic>> _departments = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _fullNameController.addListener(_onFullNameChanged);
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('Department').get();
    if (!mounted) return;
    setState(() {
      _departments = snapshot.docs
          .map((doc) => {'id': doc.id, 'name': doc['dept_name'] ?? doc.id})
          .toList();
    });
  }

  void _onFullNameChanged() {
    if (_shortNameEdited) return;
    final generated = ShortNameGenerator.generate(_fullNameController.text);
    _shortNameController.value = TextEditingValue(
      text: generated,
      selection: TextSelection.collapsed(offset: generated.length),
    );
  }

  @override
  void dispose() {
    _fullNameController.removeListener(_onFullNameChanged);
    _fullNameController.dispose();
    _shortNameController.dispose();
    _maxLecturesController.dispose();
    _emailController.dispose();
    _roleController.dispose();
    _phoneController.dispose();
    _designationController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    final fullName = _fullNameController.text.trim();
    final shortName = _shortNameController.text.trim().toUpperCase();
    final maxText = _maxLecturesController.text.trim();

    if (fullName.isEmpty) {
      _showSnack('Full name is required');
      return;
    }
    if (shortName.isEmpty) {
      _showSnack('Short name is required');
      return;
    }

    final maxLectures = int.tryParse(maxText);
    if (maxLectures == null || maxLectures <= 0) {
      _showSnack('Enter a valid max lectures per day (greater than 0)');
      return;
    }

    setState(() => _saving = true);
    try {
      await _dbService.saveFaculty(
        fullName: fullName,
        shortName: shortName,
        maxLecturesPerDay: maxLectures,
        availability: _availability,
        email: _emailController.text.trim(),
        role: _roleController.text.trim(),
        phone: _phoneController.text.trim(),
        designation: _designationController.text.trim(),
        departmentId: _selectedDepartmentId,
      );
      if (!mounted) return;
      _showSnack('Faculty saved');
      _clearForm();
    } catch (e) {
      if (!mounted) return;
      _showSnack('Error: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _clearForm() {
    _fullNameController.clear();
    _shortNameController.clear();
    _maxLecturesController.text = '4';
    _emailController.clear();
    _roleController.clear();
    _phoneController.clear();
    _designationController.clear();
    setState(() {
      _shortNameEdited = false;
      _availability = 'both';
      _selectedDepartmentId = null;
      _additionalExpanded = false;
    });
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Faculty')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InstituteFormCard(
              title: 'Main details',
              subtitle: 'Workload and availability',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _fullNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: instituteInputDecoration('Full Name *'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _shortNameController,
                    textCapitalization: TextCapitalization.characters,
                    onChanged: (_) => _shortNameEdited = true,
                    decoration: instituteInputDecoration(
                      'Short Name *',
                      hint: 'Auto-generated, editable',
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Max lecture configuration',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _maxLecturesController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: instituteInputDecoration(
                      'Max lectures per day *',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Preferred availability',
                    style: TextStyle(
                      fontSize: 13,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _availabilityOptions.entries.map((entry) {
                      final selected = _availability == entry.key;
                      return ChoiceChip(
                        label: Text(entry.value),
                        selected: selected,
                        onSelected: (_) {
                          setState(() => _availability = entry.key);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  initiallyExpanded: _additionalExpanded,
                  onExpansionChanged: (v) =>
                      setState(() => _additionalExpanded = v),
                  title: const Text(
                    'Additional details',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text(
                    'Optional — email, role, phone, designation',
                    style: TextStyle(fontSize: 12),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        children: [
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: instituteInputDecoration('Email'),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _roleController,
                            decoration: instituteInputDecoration(
                              'Role',
                              hint: 'e.g. Professor',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: instituteInputDecoration('Phone number'),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _designationController,
                            decoration: instituteInputDecoration('Designation'),
                          ),
                          if (_departments.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            InputDecorator(
                              decoration: instituteInputDecoration(
                                'Department (optional)',
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: _selectedDepartmentId,
                                  hint: const Text('None'),
                                  items: _departments.map((d) {
                                    return DropdownMenuItem<String>(
                                      value: d['id'] as String,
                                      child: Text(d['name'].toString()),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() => _selectedDepartmentId = value);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: _saving ? null : _onSave,
                child: _saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save faculty'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
