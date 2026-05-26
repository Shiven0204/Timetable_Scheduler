/// A single lecture period or break with start/end times.
class ScheduleSlot {
  ScheduleSlot({
    required this.id,
    required this.name,
    required this.startMinutes,
    required this.endMinutes,
    required this.isBreak,
  });

  final String id;
  final String name;
  /// Minutes from midnight (e.g. 9:00 → 540).
  final int startMinutes;
  final int endMinutes;
  final bool isBreak;

  static int timeToMinutes(int hour, int minute) => hour * 60 + minute;

  static String formatMinutes(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    final hh = h.toString().padLeft(2, '0');
    final mm = m.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'start': formatMinutes(startMinutes),
        'end': formatMinutes(endMinutes),
        'type': isBreak ? 'break' : 'period',
      };

  factory ScheduleSlot.fromMap(Map<String, dynamic> map) {
    final start = _parseTime(map['start']);
    final end = _parseTime(map['end']);
    final type = (map['type'] ?? 'period').toString();
    return ScheduleSlot(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      startMinutes: start,
      endMinutes: end,
      isBreak: type == 'break',
    );
  }

  static int _parseTime(Object? raw) {
    if (raw == null) return 0;
    final s = raw.toString().trim();
    final parts = s.split(':');
    if (parts.length >= 2) {
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      return timeToMinutes(h, m);
    }
    return 0;
  }

  bool get isValid => endMinutes > startMinutes;
}
