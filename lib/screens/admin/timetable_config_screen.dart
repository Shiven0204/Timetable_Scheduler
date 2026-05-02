import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:timetable_scheduler/services/timetable_service.dart';

class TimetableConfigScreen extends StatefulWidget {
  const TimetableConfigScreen({super.key});

  @override
  State<TimetableConfigScreen> createState() => _TimetableConfigScreenState();
}

class _TimetableConfigScreenState extends State<TimetableConfigScreen> {
  final TimetableService _timetableService = TimetableService();
  final _workingDaysController = TextEditingController(text: '5');
  final _periodsPerDayController = TextEditingController(text: '6');
  final _durationController = TextEditingController(text: '50');
  final _maxLecturesController = TextEditingController(text: '4');

  bool _saving = false;
  bool _preparing = false;
  bool _creatingGrid = false;
  bool _schedulingLabs = false;
  bool _generatingFull = false;

  @override
  void dispose() {
    _workingDaysController.dispose();
    _periodsPerDayController.dispose();
    _durationController.dispose();
    _maxLecturesController.dispose();
    super.dispose();
  }

  Future<void> _saveConfig() async {
    final workingDays = _workingDaysController.text.trim();
    final periods = _periodsPerDayController.text.trim();
    final duration = _durationController.text.trim();
    final maxLectures = _maxLecturesController.text.trim();

    setState(() {
      _saving = true;
    });

    try {
      final data = {
        'working_days': int.tryParse(workingDays) ?? 5,
        'periods': int.tryParse(periods) ?? 6,
        'duration_per_period': int.tryParse(duration) ?? 50,
        'max_lectures_per_day': int.tryParse(maxLectures) ?? 4,
        'updated_at': FieldValue.serverTimestamp(),
      };

      debugPrint(
        'Config -> working_days: $workingDays, periods: $periods, duration: $duration, max_lectures: $maxLectures',
      );

      await FirebaseFirestore.instance
          .collection('config')
          .doc('timetable')
          .set(data, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuration saved')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to save configuration')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _prepareData() async {
    setState(() {
      _preparing = true;
    });

    try {
      await _timetableService.prepareTimetableData();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Data Prepared')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to prepare data')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _preparing = false;
        });
      }
    }
  }

  Future<void> _createTimetableGrid() async {
    setState(() {
      _creatingGrid = true;
    });

    try {
      await _timetableService.createEmptyTimetableGrid();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Grid Created')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to create timetable grid')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _creatingGrid = false;
        });
      }
    }
  }

  Future<void> _scheduleLabs() async {
    setState(() {
      _schedulingLabs = true;
    });

    try {
      await _timetableService.scheduleLabsFromPreparedData();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Labs Scheduled')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to schedule labs')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _schedulingLabs = false;
        });
      }
    }
  }

  Future<void> _generateFullTimetable() async {
    setState(() {
      _generatingFull = true;
    });

    try {
      await _timetableService.generateFullTimetableFromPreparedData();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Timetable Generated')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to generate full timetable')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _generatingFull = false;
        });
      }
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
        title: const Text('Timetable Configuration'),
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
                  'Configuration',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _workingDaysController,
                  keyboardType: TextInputType.number,
                  decoration: _decoration('Working Days'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _periodsPerDayController,
                  keyboardType: TextInputType.number,
                  decoration: _decoration('Periods Per Day'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  decoration: _decoration('Duration per Period (minutes)'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _maxLecturesController,
                  keyboardType: TextInputType.number,
                  decoration: _decoration('Max Lectures per Day'),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _saveConfig,
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save Configuration'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _preparing ? null : _prepareData,
                    child: _preparing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Prepare Data'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _creatingGrid ? null : _createTimetableGrid,
                    child: _creatingGrid
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Create Timetable Grid'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _schedulingLabs ? null : _scheduleLabs,
                    child: _schedulingLabs
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Schedule Labs'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _generatingFull ? null : _generateFullTimetable,
                    child: _generatingFull
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Generate Full Timetable'),
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
