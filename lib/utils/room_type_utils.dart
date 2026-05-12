/// Canonical Firestore room types: [classroom] and [lab] (lowercase).
class RoomTypeUtils {
  RoomTypeUtils._();

  static const String classroom = 'classroom';
  static const String lab = 'lab';

  /// Resolves stored or legacy UI strings to [classroom], [lab], or null if unknown.
  static String? canonicalType(Object? raw) {
    final s = (raw ?? '').toString().trim();
    if (s.isEmpty) return null;
    final lower = s.toLowerCase();
    if (lower == lab) return lab;
    if (lower == classroom) return classroom;
    if (lower == 'class' || lower == 'class room') return classroom;
    return null;
  }

  static bool isLab(Object? raw) => canonicalType(raw) == lab;

  static bool isClassroom(Object? raw) => canonicalType(raw) == classroom;

  static bool isLabRoomDoc(Map<String, dynamic> room) {
    return isLab(room['room_type'] ?? room['type']);
  }

  static bool isClassroomRoomDoc(Map<String, dynamic> room) {
    return isClassroom(room['room_type'] ?? room['type']);
  }

  /// Normalizes input from the Add Room form (canonical values) or legacy strings.
  static String normalizeForFirestore(String roomType) {
    final c = canonicalType(roomType);
    if (c != null) return c;
    throw Exception('Invalid room type: use classroom or lab');
  }
}
