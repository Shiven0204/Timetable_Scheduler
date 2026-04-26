import 'package:flutter/material.dart';
import 'package:timetable_scheduler/services/database_service.dart';

class AddConfigsScreen extends StatefulWidget {
  const AddConfigsScreen({super.key});

  @override
  State<AddConfigsScreen> createState() => _AddConfigsScreenState();
}

class _AddConfigsScreenState extends State<AddConfigsScreen> {

  final _durationController = TextEditingController();
  final _periodsController = TextEditingController();
  final _daysController = TextEditingController();
  final _startTimeController = TextEditingController();

  final DatabaseService _dbService = DatabaseService();

  String _timetableType = "weekly";

  @override
  void dispose() {
    _durationController.dispose();
    _periodsController.dispose();
    _daysController.dispose();
    _startTimeController.dispose();
    super.dispose();
  }

  void _onSave() async {
    final durationText = _durationController.text.trim();
    final periodsText = _periodsController.text.trim();
    final daysText = _daysController.text.trim();
    final startTime = _startTimeController.text.trim();

    if (durationText.isEmpty ||
        periodsText.isEmpty ||
        daysText.isEmpty ||
        startTime.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill all fields')),
      );
      return;
    }

    int? duration = int.tryParse(durationText);
    int? periods = int.tryParse(periodsText);
    int? days = int.tryParse(daysText);

    if (duration == null || periods == null || days == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid numbers')),
      );
      return;
    }

    try {
      await _dbService.saveConfig(
        durationPerSlot: duration,
        periodsPerDay: periods,
        workingDays: days,
        startTime: startTime,
        timetableType: _timetableType,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Config saved')),
      );

      _durationController.clear();
      _periodsController.clear();
      _daysController.clear();
      _startTimeController.clear();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
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
        title: const Text('Add Timetable Config'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            TextField(
              controller: _durationController,
              keyboardType: TextInputType.number,
              decoration: _decoration('Duration per Slot (minutes)'),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _periodsController,
              keyboardType: TextInputType.number,
              decoration: _decoration('Periods per Day'),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _daysController,
              keyboardType: TextInputType.number,
              decoration: _decoration('Working Days'),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _startTimeController,
              decoration: _decoration('Start Time (HH:mm)'),
            ),
            const SizedBox(height: 16),

            InputDecorator(
              decoration: _decoration('Timetable Type'),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _timetableType,
                  items: const [
                    DropdownMenuItem(
                      value: 'weekly',
                      child: Text('Weekly'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _timetableType = value!;
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