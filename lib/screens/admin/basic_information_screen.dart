import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:timetable_scheduler/models/academic_session.dart';
import 'package:timetable_scheduler/models/basic_information.dart';
import 'package:timetable_scheduler/models/schedule_slot.dart';
import 'package:timetable_scheduler/services/basic_information_service.dart';
import 'package:timetable_scheduler/widgets/basic_information/schedule_slot_tile.dart';
import 'package:timetable_scheduler/widgets/basic_information/section_card.dart';
import 'package:timetable_scheduler/widgets/basic_information/selection_card.dart';

class BasicInformationScreen extends StatefulWidget {
  const BasicInformationScreen({super.key});

  @override
  State<BasicInformationScreen> createState() => _BasicInformationScreenState();
}

class _BasicInformationScreenState extends State<BasicInformationScreen> {
  final _service = BasicInformationService();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _sessionNameController = TextEditingController();
  final _cycleWeeksController = TextEditingController(text: '3');

  BasicInformation _info = BasicInformation();
  bool _loading = true;
  bool _saving = false;
  String? _selectedCustomDay;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _sessionNameController.dispose();
    _cycleWeeksController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final loaded = await _service.load();
    if (!mounted) return;

    _info = loaded ?? BasicInformation();
    if (_info.periods.isEmpty) {
      _info = _info.copyWith(periods: [_defaultPeriod(1)]);
    }
    _syncControllers();
    setState(() {
      _loading = false;
      _selectedCustomDay = _info.workingDays.isNotEmpty
          ? _info.workingDays.first
          : 'Mon';
    });
  }

  void _syncControllers() {
    _nameController.text = _info.timetableName;
    _descriptionController.text = _info.description;
    _sessionNameController.text = _info.academicSession.sessionName;
    _cycleWeeksController.text = _info.cycleWeeks.toString();
  }

  ScheduleSlot _defaultPeriod(int index) {
    final base = 9 * 60;
    final start = base + (index - 1) * 60;
    return ScheduleSlot(
      id: '${DateTime.now().millisecondsSinceEpoch}_$index',
      name: 'Period $index',
      startMinutes: start,
      endMinutes: start + 50,
      isBreak: false,
    );
  }

  ScheduleSlot _defaultBreak() {
    return ScheduleSlot(
      id: '${DateTime.now().millisecondsSinceEpoch}_b',
      name: 'Break',
      startMinutes: 12 * 60,
      endMinutes: 12 * 60 + 30,
      isBreak: true,
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  BasicInformation _buildFromForm() {
    final cycleWeeks = int.tryParse(_cycleWeeksController.text.trim()) ?? 3;
    return _info.copyWith(
      timetableName: _nameController.text,
      description: _descriptionController.text,
      cycleWeeks: cycleWeeks,
      academicSession: AcademicSession(
        sessionName: _sessionNameController.text,
        startDate: _info.academicSession.startDate,
        endDate: _info.academicSession.endDate,
      ),
    );
  }

  Future<void> _save() async {
    final merged = _buildFromForm();
    final error = BasicInformationService.validate(merged);
    if (error != null) {
      _showSnack(error);
      return;
    }

    setState(() => _saving = true);
    try {
      await _service.save(merged);
      if (!mounted) return;
      setState(() => _info = merged);
      _showSnack('Configuration saved');
    } catch (e) {
      if (!mounted) return;
      _showSnack('Could not save: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final current = isStart
        ? _info.academicSession.startDate
        : _info.academicSession.endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _info = _info.copyWith(
        academicSession: AcademicSession(
          sessionName: _sessionNameController.text,
          startDate: isStart ? picked : _info.academicSession.startDate,
          endDate: isStart ? _info.academicSession.endDate : picked,
        ),
      );
    });
  }

  String _formatDate(DateTime? d) {
    if (d == null) return 'Select date';
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  List<ScheduleSlot> _activePeriods() {
    if (_info.scheduleMode == ScheduleMode.uniform) {
      return _info.periods;
    }
    final day = _selectedCustomDay;
    if (day == null) return [];
    return _info.daySchedules[day]?.periods ?? [];
  }

  List<ScheduleSlot> _activeBreaks() {
    if (_info.scheduleMode == ScheduleMode.uniform) {
      return _info.breaks;
    }
    final day = _selectedCustomDay;
    if (day == null) return [];
    return _info.daySchedules[day]?.breaks ?? [];
  }

  void _setActivePeriods(List<ScheduleSlot> list) {
    setState(() {
      if (_info.scheduleMode == ScheduleMode.uniform) {
        _info = _info.copyWith(periods: list);
      } else {
        final day = _selectedCustomDay!;
        final ds = _info.daySchedules[day] ?? DaySchedule();
        final updated = Map<String, DaySchedule>.from(_info.daySchedules);
        updated[day] = ds.copyWith(periods: list);
        _info = _info.copyWith(daySchedules: updated);
      }
    });
  }

  void _setActiveBreaks(List<ScheduleSlot> list) {
    setState(() {
      if (_info.scheduleMode == ScheduleMode.uniform) {
        _info = _info.copyWith(breaks: list);
      } else {
        final day = _selectedCustomDay!;
        final ds = _info.daySchedules[day] ?? DaySchedule();
        final updated = Map<String, DaySchedule>.from(_info.daySchedules);
        updated[day] = ds.copyWith(breaks: list);
        _info = _info.copyWith(daySchedules: updated);
      }
    });
  }

  void _ensureDaySchedules() {
    final updated = Map<String, DaySchedule>.from(_info.daySchedules);
    for (final day in _info.workingDays) {
      updated.putIfAbsent(
        day,
        () => DaySchedule(
          periods: List<ScheduleSlot>.from(_info.periods),
          breaks: List<ScheduleSlot>.from(_info.breaks),
        ),
      );
    }
    _info = _info.copyWith(daySchedules: updated);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Basic Information'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Configure timetable details and bell schedule before generation.',
                    style: TextStyle(
                      fontSize: 14,
                      color: scheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTimetableInfoSection(),
                  _buildAcademicSessionSection(),
                  _buildBellScheduleSection(),
                  _buildWorkingDaysSection(),
                  _buildPeriodsBreaksSection(),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text('Save configuration'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTimetableInfoSection() {
    return SectionCard(
      title: 'Timetable Information',
      icon: Icons.description_outlined,
      child: Column(
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Timetable Name *',
              border: OutlineInputBorder(),
            ),
            maxLength: 100,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              hintText: 'Notes about this timetable…',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            maxLines: 3,
            maxLength: 500,
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicSessionSection() {
    return SectionCard(
      title: 'Academic Session',
      subtitle: 'Optional — fill all three fields for proper tracking',
      icon: Icons.calendar_today_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Session details are optional. If you start, complete name, start, and end dates.',
                    style: TextStyle(fontSize: 12, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _sessionNameController,
            decoration: const InputDecoration(
              labelText: 'Session Name',
              hintText: 'e.g. 2025–2026',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DateButton(
                  label: 'Start Date',
                  value: _formatDate(_info.academicSession.startDate),
                  onTap: () => _pickDate(isStart: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DateButton(
                  label: 'End Date',
                  value: _formatDate(_info.academicSession.endDate),
                  onTap: () => _pickDate(isStart: false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBellScheduleSection() {
    return SectionCard(
      title: 'Bell Schedule',
      icon: Icons.schedule_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Schedule type',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 10),
          ...ScheduleType.values.map((type) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SelectionCard(
                title: type.label,
                description: type.description,
                selected: _info.scheduleType == type,
                onTap: () => setState(() => _info = _info.copyWith(scheduleType: type)),
              ),
            );
          }),
          if (_info.scheduleType == ScheduleType.custom) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _cycleWeeksController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Number of weeks in cycle',
                border: OutlineInputBorder(),
              ),
            ),
          ],
          const SizedBox(height: 20),
          const Text(
            'Default schedule',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'Configure lectures and breaks for the timetable',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          SelectionCard(
            title: ScheduleMode.uniform.label,
            description: ScheduleMode.uniform.description,
            selected: _info.scheduleMode == ScheduleMode.uniform,
            onTap: () => setState(() => _info = _info.copyWith(scheduleMode: ScheduleMode.uniform)),
          ),
          const SizedBox(height: 8),
          SelectionCard(
            title: ScheduleMode.customDay.label,
            description: ScheduleMode.customDay.description,
            selected: _info.scheduleMode == ScheduleMode.customDay,
            onTap: () {
              setState(() {
                _info = _info.copyWith(scheduleMode: ScheduleMode.customDay);
                _ensureDaySchedules();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWorkingDaysSection() {
    final count = _info.workingDays.length;
    return SectionCard(
      title: 'Working Days',
      icon: Icons.view_week_outlined,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () {
              setState(() {
                _info = _info.copyWith(
                  workingDays: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
                );
                _selectedCustomDay = 'Mon';
                if (_info.scheduleMode == ScheduleMode.customDay) {
                  _ensureDaySchedules();
                }
              });
            },
            child: const Text('Weekdays'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _info = _info.copyWith(workingDays: []);
                _selectedCustomDay = null;
              });
            },
            child: const Text('Clear'),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: BasicInformation.allWeekdays.map((day) {
              final selected = _info.workingDays.contains(day);
              return FilterChip(
                label: Text(day),
                selected: selected,
                onSelected: (on) {
                  setState(() {
                    final days = List<String>.from(_info.workingDays);
                    if (on) {
                      if (!days.contains(day)) days.add(day);
                    } else {
                      days.remove(day);
                    }
                    days.sort((a, b) => BasicInformation.allWeekdays
                        .indexOf(a)
                        .compareTo(BasicInformation.allWeekdays.indexOf(b)));
                    _info = _info.copyWith(workingDays: days);
                    if (_selectedCustomDay == null && days.isNotEmpty) {
                      _selectedCustomDay = days.first;
                    } else if (_selectedCustomDay != null &&
                        !days.contains(_selectedCustomDay)) {
                      _selectedCustomDay =
                          days.isNotEmpty ? days.first : null;
                    }
                    if (_info.scheduleMode == ScheduleMode.customDay) {
                      _ensureDaySchedules();
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Text(
            '$count day${count == 1 ? '' : 's'} selected',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodsBreaksSection() {
    final periods = _activePeriods();
    final breaks = _activeBreaks();

    return SectionCard(
      title: 'Periods & Breaks',
      icon: Icons.access_time,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_info.scheduleMode == ScheduleMode.customDay &&
              _info.workingDays.isNotEmpty) ...[
            DropdownButtonFormField<String>(
              key: ValueKey(_selectedCustomDay),
              initialValue: _selectedCustomDay,
              decoration: const InputDecoration(
                labelText: 'Edit schedule for',
                border: OutlineInputBorder(),
              ),
              items: _info.workingDays
                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCustomDay = v),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Lectures',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  final list = List<ScheduleSlot>.from(periods)
                    ..add(_defaultPeriod(periods.length + 1));
                  _setActivePeriods(list);
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Period'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...periods.map((slot) {
            return ScheduleSlotTile(
              key: ValueKey(slot.id),
              slot: slot,
              nameLabel: 'Period name',
              onChanged: (updated) {
                final list = periods.map((s) => s.id == slot.id ? updated : s).toList();
                _setActivePeriods(list);
              },
              onRemove: () {
                _setActivePeriods(periods.where((s) => s.id != slot.id).toList());
              },
            );
          }),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Breaks',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  final list = List<ScheduleSlot>.from(breaks)..add(_defaultBreak());
                  _setActiveBreaks(list);
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Break'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...breaks.map((slot) {
            return ScheduleSlotTile(
              key: ValueKey(slot.id),
              slot: slot,
              nameLabel: 'Break name',
              onChanged: (updated) {
                final list = breaks.map((s) => s.id == slot.id ? updated : s).toList();
                _setActiveBreaks(list);
              },
              onRemove: () {
                _setActiveBreaks(breaks.where((s) => s.id != slot.id).toList());
              },
            );
          }),
        ],
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
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        child: Text(value),
      ),
    );
  }
}
