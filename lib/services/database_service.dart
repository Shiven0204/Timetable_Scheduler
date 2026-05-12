import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

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

  Future<void> saveProgram({
    required String programName,
    required String branchName,
    required String departmentId,
  }) async {
    try {
      if (programName.isEmpty ||
          branchName.isEmpty ||
          departmentId.isEmpty) {
        throw Exception("Fields cannot be empty");
      }
      await _db.collection('Programs').add({
        'program_name': programName,
        'branch_name': branchName,
        'department_id': departmentId,
        'created_at': FieldValue.serverTimestamp(),
      });

      debugPrint('Program saved successfully');
    } catch (e) {
      debugPrint('Error saving program: $e');
      rethrow;
    }
  }

  Future<void> saveFaculty({
    required String facultyName,
    required String email,
    required List<String> expertise,
    required int maxLecturesPerDay,
    required String departmentId,
  }) async {
    try {
      if (facultyName.isEmpty || email.isEmpty || departmentId.isEmpty) {
        throw Exception("Fields cannot be empty");
      }

      await _db.collection('Faculty').add({
        'faculty_name': facultyName,
        'email': email,
        'expertise': expertise,
        'max_lectures_per_day': maxLecturesPerDay,
        'department_id': departmentId,
        'created_at': FieldValue.serverTimestamp(),
      });

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

  Future<void> saveMapping({
    required String facultyId,
    required String subjectId,
    required String programId,
    required String roomId,
    String? departmentId,
  }) async {
    try {
      final data = <String, dynamic>{
        'faculty_id': facultyId,
        'subject_id': subjectId,
        'program_id': programId,
        'room_id': roomId,
        'created_at': FieldValue.serverTimestamp(),
      };
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
    required String roomName,
    required String roomType,
    required int capacity,
  }) async {
    try {
      if (roomName.isEmpty || roomType.isEmpty) {
        throw Exception("Fields cannot be empty");
      }

      await _db.collection('Rooms').add({
        'room_name': roomName,
        'room_type': roomType,
        'capacity': capacity,
        'created_at': FieldValue.serverTimestamp(),
      });

      debugPrint('Room saved successfully');
    } catch (e) {
      debugPrint('Error saving room: $e');
      rethrow;
    }
  }
}
