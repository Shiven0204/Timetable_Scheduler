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
    required int year,
    required String departmentId, // 🔥 doc.id reference
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
        'year': year,
        'department_id': departmentId, // 🔥 linking happens here
        'created_at': FieldValue.serverTimestamp(),
      });

      print("✅ Program saved successfully");

    } catch (e) {
      print("❌ Error saving program: $e");
      rethrow;
    }
  }
}