import 'package:flutter/material.dart';
import 'package:timetable_scheduler/models/schedule_slot.dart';

typedef SlotChanged = void Function(ScheduleSlot updated);

/// Editable row for one period or break with name + time pickers.
class ScheduleSlotTile extends StatelessWidget {
  const ScheduleSlotTile({
    super.key,
    required this.slot,
    required this.onChanged,
    required this.onRemove,
    this.nameLabel = 'Name',
  });

  final ScheduleSlot slot;
  final SlotChanged onChanged;
  final VoidCallback onRemove;
  final String nameLabel;

  static Future<TimeOfDay?> pickTime(
    BuildContext context,
    int minutes,
  ) async {
    final initial = TimeOfDay(
      hour: minutes ~/ 60,
      minute: minutes % 60,
    );
    return showTimePicker(context: context, initialTime: initial);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: slot.name,
                  decoration: InputDecoration(
                    labelText: nameLabel,
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (v) => onChanged(_copy(slot, name: v)),
                ),
              ),
              IconButton(
                tooltip: 'Remove',
                onPressed: onRemove,
                icon: Icon(Icons.close, color: scheme.error),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TimeField(
                  label: 'Start',
                  minutes: slot.startMinutes,
                  onPick: () async {
                    final t = await pickTime(context, slot.startMinutes);
                    if (t == null) return;
                    onChanged(_copy(
                      slot,
                      start: ScheduleSlot.timeToMinutes(t.hour, t.minute),
                    ));
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TimeField(
                  label: 'End',
                  minutes: slot.endMinutes,
                  onPick: () async {
                    final t = await pickTime(context, slot.endMinutes);
                    if (t == null) return;
                    onChanged(_copy(
                      slot,
                      end: ScheduleSlot.timeToMinutes(t.hour, t.minute),
                    ));
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  ScheduleSlot _copy(
    ScheduleSlot s, {
    String? name,
    int? start,
    int? end,
  }) {
    return ScheduleSlot(
      id: s.id,
      name: name ?? s.name,
      startMinutes: start ?? s.startMinutes,
      endMinutes: end ?? s.endMinutes,
      isBreak: s.isBreak,
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.minutes,
    required this.onPick,
  });

  final String label;
  final int minutes;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.schedule, size: 20),
        ),
        child: Text(ScheduleSlot.formatMinutes(minutes)),
      ),
    );
  }
}
