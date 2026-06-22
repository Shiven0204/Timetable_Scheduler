import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:timetable_scheduler/services/database_service.dart';
import 'package:timetable_scheduler/utils/short_name_generator.dart';
import 'package:timetable_scheduler/widgets/institute_form_card.dart';

class AddSubjectScreen extends StatefulWidget {
  const AddSubjectScreen({super.key});

  @override
  State<AddSubjectScreen> createState() => _AddSubjectScreenState();
}

class _AddSubjectScreenState extends State<AddSubjectScreen> {
  final _subjectNameController = TextEditingController();
  final _shortNameController = TextEditingController();
  final _creditsController = TextEditingController();
  List<Map<String, dynamic>> _subjects = [];
  int _visibleSubjects = 5;
  final _searchController = TextEditingController();
  final Set<String> _selectedSubjectIds = {};

  String _searchText = '';

  final DatabaseService _dbService = DatabaseService();

  bool _isLab = false;
  bool _shortNameEdited = false;

  String? _selectedProgramId;
  List<Map<String, dynamic>> _programs = [];

  @override
  void initState() {
    super.initState();
    _subjectNameController.addListener(_onNameChanged);
    _loadPrograms();
    _loadSubjects();
  }

  void _onNameChanged() {
    if (_shortNameEdited) return;
    final generated = ShortNameGenerator.generate(_subjectNameController.text);
    _shortNameController.value = TextEditingValue(
      text: generated,
      selection: TextSelection.collapsed(offset: generated.length),
    );
  }

  Future<void> _deleteSelectedSubjects() async {
    try {
      for (final id in _selectedSubjectIds) {
        await FirebaseFirestore.instance
            .collection('Subjects')
            .doc(id)
            .delete();
      }

      _selectedSubjectIds.clear();

      await _loadSubjects();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected subjects deleted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _loadSubjects() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('Subjects')
        .orderBy('created_at', descending: true)
        .get();

    if (!mounted) return;

    setState(() {
      _subjects = snapshot.docs.map((doc) {
        return {'id': doc.id, 'subject_name': doc['subject_name'] ?? ''};
      }).toList();
    });
  }

  Future<void> _loadPrograms() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('Programs')
        .get();

    if (!mounted) return;
    setState(() {
      _programs = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'program_name': doc['program_name'] ?? doc['name'],
          'branch_name': doc['branch_name'] ?? doc['short_name'],
        };
      }).toList();
    });
  }

  @override
  void dispose() {
    _subjectNameController.removeListener(_onNameChanged);
    _subjectNameController.dispose();
    _shortNameController.dispose();
    _creditsController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSave() async {
    final subjectName = _subjectNameController.text.trim();
    final shortName = _shortNameController.text.trim().toUpperCase();
    final creditsText = _creditsController.text.trim();

    if (subjectName.isEmpty ||
        shortName.isEmpty ||
        creditsText.isEmpty ||
        _selectedProgramId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Fill all fields')));
      return;
    }

    try {
      int credits = int.tryParse(creditsText) ?? 0;
      if (credits <= 0) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Enter valid credits')));
        return;
      }

      await _dbService.saveSubject(
        subjectName: subjectName,
        shortName: shortName,
        credits: credits,
        isLab: _isLab,
        programId: _selectedProgramId!,
      );

      await _loadSubjects();
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Subject saved')));

      _subjectNameController.clear();
      _shortNameController.clear();
      _creditsController.clear();

      setState(() {
        _isLab = false;
        _shortNameEdited = false;
        _selectedProgramId = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredSubjects = _subjects.where((subject) {
      final name = subject['subject_name'].toString().toLowerCase();

      return name.contains(_searchText.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Add Subject')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: InstituteFormCard(
          title: 'Subject & lecture details',
          subtitle:
              'Credits drive default weekly frequency. Enable Lab means theory + lab session.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _subjectNameController,
                textCapitalization: TextCapitalization.words,
                decoration: instituteInputDecoration('Subject Name *'),
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
              const SizedBox(height: 16),
              TextField(
                controller: _creditsController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: instituteInputDecoration('Credits *'),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Enable Lab'),
                subtitle: const Text(
                  'Theory lectures + one weekly lab session',
                ),
                value: _isLab,
                onChanged: (value) {
                  setState(() {
                    _isLab = value;
                  });
                },
              ),
              const SizedBox(height: 8),
              InputDecorator(
                decoration: instituteInputDecoration('Program *'),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedProgramId,
                    hint: const Text('Select program'),
                    items: _programs.map<DropdownMenuItem<String>>((p) {
                      return DropdownMenuItem<String>(
                        value: p['id'],
                        child: Text(
                          '${p['program_name']} - ${p['branch_name']}',
                        ),
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
                child: FilledButton(
                  onPressed: _onSave,
                  child: const Text('Save subject'),
                ),
              ),

              const SizedBox(height: 32),

              const Divider(),

              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recently Added Subjects',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),

                  if (_selectedSubjectIds.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.delete),
                      tooltip: 'Delete Selected',
                      onPressed: _deleteSelectedSubjects,
                    ),
                ],
              ),

              const SizedBox(height: 12),

              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search Subject',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchText = value;
                    _visibleSubjects = 5;
                  });
                },
              ),

              const SizedBox(height: 16),

              const SizedBox(height: 12),
              if (filteredSubjects.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    _searchText.isEmpty
                        ? 'No subjects added yet'
                        : 'No matching subjects found',
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredSubjects.length < _visibleSubjects
                      ? filteredSubjects.length
                      : _visibleSubjects,
                  itemBuilder: (context, index) {
                    final subject = filteredSubjects[index];
                    final id = subject['id'];

                    return CheckboxListTile(
                      dense: true,
                      value: _selectedSubjectIds.contains(id),
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(subject['subject_name']),
                      secondary: const Icon(Icons.book_outlined),
                      onChanged: (selected) {
                        setState(() {
                          if (selected ?? false) {
                            _selectedSubjectIds.add(id);
                          } else {
                            _selectedSubjectIds.remove(id);
                          }
                        });
                      },
                    );
                  },
                ),
              if (filteredSubjects.length > _visibleSubjects)
                Center(
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _visibleSubjects += 5;
                      });
                    },
                    child: const Text('Load More'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
