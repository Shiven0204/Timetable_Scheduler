class AcademicSession {
  AcademicSession({
    this.sessionName = '',
    this.startDate,
    this.endDate,
  });

  final String sessionName;
  final DateTime? startDate;
  final DateTime? endDate;

  bool get hasAnyField =>
      sessionName.trim().isNotEmpty ||
      startDate != null ||
      endDate != null;

  bool get isComplete =>
      sessionName.trim().isNotEmpty && startDate != null && endDate != null;

  Map<String, dynamic> toMap() => {
        'session_name': sessionName.trim(),
        'start_date': startDate?.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
      };

  factory AcademicSession.fromMap(Map<String, dynamic>? map) {
    if (map == null) return AcademicSession();
    return AcademicSession(
      sessionName: (map['session_name'] ?? '').toString(),
      startDate: _parseDate(map['start_date']),
      endDate: _parseDate(map['end_date']),
    );
  }

  static DateTime? _parseDate(Object? raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    return DateTime.tryParse(raw.toString());
  }
}
