import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:timetable_scheduler/models/basic_information.dart';
import 'package:timetable_scheduler/models/schedule_slot.dart';
import 'package:timetable_scheduler/services/basic_information_service.dart';
import 'package:timetable_scheduler/widgets/basic_information/schedule_slot_tile.dart';
import 'package:timetable_scheduler/widgets/basic_information/selection_card.dart';
import 'package:timetable_scheduler/widgets/institute_form_card.dart';

class BellScheduleForm extends StatefulWidget {
  const BellScheduleForm({
    required this.baseInfo,
    this.embeddedInDialog = false,
    super.key,
  });

  final BasicInformation baseInfo;
  final bool embeddedInDialog;

  @override
  State<BellScheduleForm> createState() => BellScheduleFormState();
}

class BellScheduleFormState extends State<BellScheduleForm> {
  final _service = BasicInformationService();
  final _cycleWeeksController = TextEditingController(text: '3');

  late BasicInformation _info;
  String? _selectedCustomDay;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _info = _normalizeInfo(widget.baseInfo);
    _cycleWeeksController.text = _info.cycleWeeks.toString();
    _selectedCustomDay =
        _info.workingDays.isNotEmpty ? _info.workingDays.first : 'Mon';
  }

  @override
  void dispose() {
    _cycleWeeksController.dispose();
    super.dispose();
  }

  BasicInformation _normalizeInfo(BasicInformation info) {
    var normalized = info;
    if (normalized.periods.isEmpty) {
      normalized = normalized.copyWith(periods: [_defaultPeriod(1)]);
    }
    return normalized;
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
    setState(() => _info = _info.copyWith(daySchedules: updated));
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

  BasicInformation _buildMerged(BasicInformation current) {
    final cycleWeeks = int.tryParse(_cycleWeeksController.text.trim()) ?? 3;
    return current.copyWith(
      scheduleType: _info.scheduleType,
      cycleWeeks: cycleWeeks,
      scheduleMode: _info.scheduleMode,
      workingDays: List<String>.from(_info.workingDays),
      periods: List<ScheduleSlot>.from(_info.periods),
      breaks: List<ScheduleSlot>.from(_info.breaks),
      daySchedules: Map<String, DaySchedule>.from(_info.daySchedules),
    );
  }

  Future<bool> submit() async {
    setState(() => _saving = true);
    try {
      final current = await _service.load() ?? widget.baseInfo;
      final merged = _buildMerged(current);
      final error = BasicInformationService.validateBellSchedule(merged);
      if (error != null) {
        _showSnack(error);
        return false;
      }
      await _service.save(merged);
      if (!mounted) return false;
      if (!widget.embeddedInDialog) {
        _showSnack('Bell schedule saved');
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
    final count = _info.workingDays.length;
    final periods = _activePeriods();
    final breaks = _activeBreaks();
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InstituteFormCard(
          title: 'Schedule type',
          child: Column(
            children: [
              ...ScheduleType.values.map((type) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SelectionCard(
                    title: type.label,
                    description: type.description,
                    selected: _info.scheduleType == type,
                    onTap: () =>
                        setState(() => _info = _info.copyWith(scheduleType: type)),
                  ),
                );
              }),
              if (_info.scheduleType == ScheduleType.custom) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _cycleWeeksController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: instituteInputDecoration('Number of weeks in cycle'),
                ),
              ],
              const SizedBox(height: 12),
              SelectionCard(
                title: ScheduleMode.uniform.label,
                description: ScheduleMode.uniform.description,
                selected: _info.scheduleMode == ScheduleMode.uniform,
                onTap: () => setState(
                  () => _info = _info.copyWith(scheduleMode: ScheduleMode.uniform),
                ),
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
        ),
        const SizedBox(height: 16),
        InstituteFormCard(
          title: 'Working days',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Spacer(),
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
                        days.sort(
                          (a, b) => BasicInformation.allWeekdays
                              .indexOf(a)
                              .compareTo(BasicInformation.allWeekdays.indexOf(b)),
                        );
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
                  color: scheme.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        InstituteFormCard(
          title: 'Periods & breaks',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_info.scheduleMode == ScheduleMode.customDay &&
                  _info.workingDays.isNotEmpty) ...[
                DropdownButtonFormField<String>(
                  key: ValueKey(_selectedCustomDay),
                  initialValue: _selectedCustomDay,
                  decoration: instituteInputDecoration('Edit schedule for'),
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
                    final list =
                        periods.map((s) => s.id == slot.id ? updated : s).toList();
                    _setActivePeriods(list);
                  },
                  onRemove: () {
                    _setActivePeriods(
                      periods.where((s) => s.id != slot.id).toList(),
                    );
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
                      final list = List<ScheduleSlot>.from(breaks)
                        ..add(_defaultBreak());
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
                    final list =
                        breaks.map((s) => s.id == slot.id ? updated : s).toList();
                    _setActiveBreaks(list);
                  },
                  onRemove: () {
                    _setActiveBreaks(breaks.where((s) => s.id != slot.id).toList());
                  },
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embeddedInDialog) {
      return _buildForm();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Bell Schedule')),
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
