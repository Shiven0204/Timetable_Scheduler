import 'package:flutter/material.dart';

/// Weekly timetable table: [days] × P1…Pn.
enum TimetableGridMode {
  /// Lines: subject, faculty, room.
  programView,

  /// Lines: subject, program, room.
  facultyView,
}

class TimetableGrid extends StatelessWidget {
  const TimetableGrid({
    super.key,
    required this.days,
    required this.periodsPerDay,
    required this.grid,
    this.mode = TimetableGridMode.programView,
    this.columnWidth = 118,
    this.highlightLabSlots = true,
  });

  final List<String> days;
  final int periodsPerDay;
  final Map<String, List<Map<String, dynamic>?>> grid;
  final TimetableGridMode mode;
  final double columnWidth;
  final bool highlightLabSlots;

  static const Color _labTint = Color(0xFFE8F5E9);

  @override
  Widget build(BuildContext context) {
    final borderColor = Theme.of(context).colorScheme.outlineVariant;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        defaultColumnWidth: FixedColumnWidth(columnWidth),
        border: TableBorder.all(color: borderColor, width: 1),
        children: [
          TableRow(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            children: [
              _headerCell(context, 'Day'),
              for (var p = 0; p < periodsPerDay; p++)
                _headerCell(context, 'P${p + 1}'),
            ],
          ),
          for (final day in days)
            TableRow(
              children: [
                _headerCell(context, day),
                for (var p = 0; p < periodsPerDay; p++)
                  _slotCell(context, grid[day]?[p]),
              ],
            ),
        ],
      ),
    );
  }

  Widget _headerCell(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _slotCell(BuildContext context, Map<String, dynamic>? slot) {
    if (slot == null) {
      return _emptySlot(context);
    }

    final subject = (slot['subject'] ?? '').toString().trim();
    final line2 = mode == TimetableGridMode.facultyView
        ? (slot['program'] ?? '').toString().trim()
        : (slot['faculty'] ?? '').toString().trim();
    final room = (slot['room'] ?? '').toString().trim();
    final isLab = highlightLabSlots &&
        (slot['type'] ?? '').toString().toLowerCase() == 'lab';

    if (subject.isEmpty && line2.isEmpty && room.isEmpty) {
      return _emptySlot(context);
    }

    final scheme = Theme.of(context).colorScheme;

    return Container(
      color: isLab ? _labTint : null,
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            subject.isNotEmpty ? subject : '—',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
          if (line2.isNotEmpty)
            Text(
              line2,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: scheme.onSurfaceVariant,
              ),
            ),
          if (room.isNotEmpty)
            Text(
              room,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: scheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }

  Widget _emptySlot(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Text(
        '-',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }
}
