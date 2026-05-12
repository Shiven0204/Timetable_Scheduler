import 'package:cloud_firestore/cloud_firestore.dart';

/// Batch-resolves Firestore document IDs to display names for timetable UIs.
class TimetableNameResolver {
  TimetableNameResolver({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  static const int _whereInLimit = 30;

  static const List<String> _subjectCollections = ['Subjects', 'subjects'];
  static const List<String> _facultyCollections = ['Faculty', 'faculty'];
  static const List<String> _roomCollections = ['rooms', 'Rooms', 'Room'];
  static const List<String> _programCollections = ['Programs', 'programs'];

  Future<TimetableResolvedNames> resolve({
    required Set<String> subjectIds,
    required Set<String> facultyIds,
    required Set<String> roomIds,
    Set<String> programIds = const {},
  }) async {
    final subjects = await _resolveAcrossCollections(
      subjectIds,
      _subjectCollections,
      const ['subject_name', 'name', 'title'],
    );
    final faculty = await _resolveAcrossCollections(
      facultyIds,
      _facultyCollections,
      const ['faculty_name', 'name', 'full_name'],
    );
    final rooms = await _resolveAcrossCollections(
      roomIds,
      _roomCollections,
      const ['room_name', 'name', 'room_no', 'number'],
    );
    final programs = programIds.isEmpty
        ? <String, String>{}
        : await _resolveAcrossCollections(
            programIds,
            _programCollections,
            const ['program_name', 'name'],
          );
    return TimetableResolvedNames(
      subjects: subjects,
      faculty: faculty,
      rooms: rooms,
      programs: programs,
    );
  }

  Future<Map<String, String>> _resolveAcrossCollections(
    Set<String> ids,
    List<String> collections,
    List<String> nameFields,
  ) async {
    if (ids.isEmpty) {
      return {};
    }
    var pending = Set<String>.from(ids);
    final out = <String, String>{};

    for (final collection in collections) {
      if (pending.isEmpty) {
        break;
      }
      try {
        final chunk = await _fetchByDocumentIds(
          collection,
          pending,
          nameFields,
        );
        out.addAll(chunk);
        pending = pending.difference(chunk.keys.toSet());
      } catch (_) {
        continue;
      }
    }

    for (final id in pending) {
      out[id] = id;
    }
    return out;
  }

  Future<Map<String, String>> _fetchByDocumentIds(
    String collection,
    Set<String> ids,
    List<String> nameFields,
  ) async {
    final out = <String, String>{};
    final list = ids.toList();
    for (var i = 0; i < list.length; i += _whereInLimit) {
      final end = (i + _whereInLimit < list.length) ? i + _whereInLimit : list.length;
      final sub = list.sublist(i, end);
      if (sub.isEmpty) {
        continue;
      }
      final snap = await _db
          .collection(collection)
          .where(FieldPath.documentId, whereIn: sub)
          .get();
      for (final doc in snap.docs) {
        final data = doc.data();
        var name = doc.id;
        for (final field in nameFields) {
          final v = data[field];
          if (v != null && v.toString().trim().isNotEmpty) {
            name = v.toString();
            break;
          }
        }
        out[doc.id] = name;
      }
    }
    return out;
  }
}

class TimetableResolvedNames {
  const TimetableResolvedNames({
    required this.subjects,
    required this.faculty,
    required this.rooms,
    required this.programs,
  });

  final Map<String, String> subjects;
  final Map<String, String> faculty;
  final Map<String, String> rooms;
  final Map<String, String> programs;
}
