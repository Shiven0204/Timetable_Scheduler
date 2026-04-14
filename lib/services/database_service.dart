import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Department Collection Reference

  Future<void> saveDepartment(String name) async {
    try {
      if (name.isEmpty) {
        throw Exception("Department name cannot be empty");
      }

      await _db.collection('Department').add({
        'dept_name': name,
        'created_at': FieldValue.serverTimestamp(),
      });

      print("✅ Department saved successfully");
    } catch (e) {
      print("❌ Error saving department: $e");
      rethrow;
    }
  }

  // Program Collection Reference

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


    print("✅ Program saved successfully");
  } catch (e) {
    print("❌ Error saving program: $e");
    rethrow;
  }
}

  // Faculty Collection Reference

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

      print("✅ Faculty saved successfully");
    } catch (e) {
      print("❌ Error saving faculty: $e");
      rethrow;
    }
  }

  // Subject Collection Reference

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

      print("✅ Subject saved successfully");
    } catch (e) {
      print("❌ Error saving subject: $e");
      rethrow;
    }
  }

  //Mapping Collection Reference

  Future<void> saveMapping({
  required String facultyId,
  required String subjectId,
  required String programId,
}) async {
  try {
    await _db.collection('Mappings').add({
      'faculty_id': facultyId,
      'subject_id': subjectId,
      'program_id': programId,
      'created_at': FieldValue.serverTimestamp(),
    });

    print("✅ Mapping saved");

  } catch (e) {
    print("❌ Error saving mapping: $e");
    rethrow;
  }
}
}
