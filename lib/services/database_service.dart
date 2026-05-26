import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:timetable_scheduler/utils/room_type_utils.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> saveDepartment(String name) async {
    try {
      if (name.isEmpty) {
        throw Exception("Department name cannot be empty");
      }

      await _db.collection('Department').add({
        'dept_name': name,
        'created_at': FieldValue.serverTimestamp(),
      });

      debugPrint('Department saved successfully');
    } catch (e) {
      debugPrint('Error saving department: $e');
      rethrow;
    }
  }

  /// Saves program with canonical fields plus legacy keys for timetable/mapping UIs.
  Future<void> saveProgram({
    required String name,
    required String shortName,
    int? studentCount,
    String? departmentId,
  }) async {
    try {
      if (name.isEmpty || shortName.isEmpty) {
        throw Exception('Program name and short name are required');
      }

      final data = <String, dynamic>{
        'name': name,
        'short_name': shortName,
        'program_name': name,
        'branch_name': shortName,
        'created_at': FieldValue.serverTimestamp(),
      };
      if (studentCount != null) {
        data['student_count'] = studentCount;
      }
      if (departmentId != null && departmentId.trim().isNotEmpty) {
        data['department_id'] = departmentId.trim();
      }

      await _db.collection('Programs').add(data);

      debugPrint('Program saved successfully');
    } catch (e) {
      debugPrint('Error saving program: $e');
      rethrow;
    }
  }

  /// Legacy program save (subject/mapping flows that still pass branch + department).
  Future<void> saveProgramLegacy({
    required String programName,
    required String branchName,
    required String departmentId,
  }) async {
    await saveProgram(
      name: programName,
      shortName: branchName,
      departmentId: departmentId,
    );
  }

  Future<void> saveFaculty({
    required String fullName,
    required String shortName,
    required int maxLecturesPerDay,
    required String availability,
    String? email,
    String? role,
    String? phone,
    String? designation,
    String? departmentId,
  }) async {
    try {
      if (fullName.isEmpty || shortName.isEmpty) {
        throw Exception('Faculty name and short name are required');
      }
      if (maxLecturesPerDay <= 0) {
        throw Exception('Max lectures per day must be greater than zero');
      }

      final data = <String, dynamic>{
        'full_name': fullName,
        'short_name': shortName,
        'faculty_name': fullName,
        'max_lectures_per_day': maxLecturesPerDay,
        'availability': availability,
        'created_at': FieldValue.serverTimestamp(),
      };
      if (email != null && email.trim().isNotEmpty) {
        data['email'] = email.trim();
      }
      if (role != null && role.trim().isNotEmpty) {
        data['role'] = role.trim();
      }
      if (phone != null && phone.trim().isNotEmpty) {
        data['phone'] = phone.trim();
      }
      if (designation != null && designation.trim().isNotEmpty) {
        data['designation'] = designation.trim();
      }
      if (departmentId != null && departmentId.trim().isNotEmpty) {
        data['department_id'] = departmentId.trim();
      }

      await _db.collection('Faculty').add(data);

      debugPrint('Faculty saved successfully');
    } catch (e) {
      debugPrint('Error saving faculty: $e');
      rethrow;
    }
  }

  Future<void> saveSubject({
    required String subjectName,
    required int credits,
    required bool isLab,
    required String programId,
  }) async {
    try {
      if (subjectName.isEmpty || programId.isEmpty) {
        throw Exception("Fields cannot be empty");
      }

      await _db.collection('Subjects').add({
        'subject_name': subjectName,
        'credits': credits,
        'is_lab': isLab,
        'program_id': programId,
        'created_at': FieldValue.serverTimestamp(),
      });

      debugPrint('Subject saved successfully');
    } catch (e) {
      debugPrint('Error saving subject: $e');
      rethrow;
    }
  }

  /// [theoryRoomId] = classroom for all theory periods. [labRoomId] required when
  /// the subject has both theory and lab (`is_lab` on subject document).
  Future<void> saveMapping({
    required String facultyId,
    required String subjectId,
    required String programId,
    required String theoryRoomId,
    String? labRoomId,
    String? departmentId,
  }) async {
    try {
      final data = <String, dynamic>{
        'faculty_id': facultyId,
        'subject_id': subjectId,
        'program_id': programId,
        'theory_room_id': theoryRoomId,
        'room_id': theoryRoomId,
        'created_at': FieldValue.serverTimestamp(),
      };
      if (labRoomId != null && labRoomId.trim().isNotEmpty) {
        data['lab_room_id'] = labRoomId.trim();
      }
      if (departmentId != null && departmentId.trim().isNotEmpty) {
        data['department_id'] = departmentId.trim();
      }
      await _db.collection('Mappings').add(data);

      debugPrint('Mapping saved');
    } catch (e) {
      debugPrint('Error saving mapping: $e');
      rethrow;
    }
  }

  Future<void> saveRoom({
    required String name,
    required String roomType,
    required int capacity,
    String? buildingName,
  }) async {
    try {
      if (name.isEmpty || roomType.isEmpty) {
        throw Exception('Room name and type are required');
      }
      if (capacity <= 0) {
        throw Exception('Capacity must be greater than zero');
      }

      final normalizedType = RoomTypeUtils.normalizeForFirestore(roomType);
      final data = <String, dynamic>{
        'name': name,
        'room_name': name,
        'room_type': normalizedType,
        'capacity': capacity,
        'created_at': FieldValue.serverTimestamp(),
      };
      if (buildingName != null && buildingName.trim().isNotEmpty) {
        data['building_name'] = buildingName.trim();
      }

      await _db.collection('Rooms').add(data);

      debugPrint('Room saved successfully');
    } catch (e) {
      debugPrint('Error saving room: $e');
      rethrow;
    }
  }
}
