import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Save Department
  Future<void> saveDepartment(String name) async {
    try {
      // 1. Validate input
      if (name.isEmpty) {
        throw Exception("Department name cannot be empty");
      }

      // 2. Prepare data
      final data = {
        'dept_name': name,
        'created_at': FieldValue.serverTimestamp(),
      };

      // 3. Send to Firestore
      await _db.collection('Department').add(data);

      print("✅ Department saved successfully");

    } catch (e) {
      print("❌ Error saving department: $e");
      rethrow;
    }
  }
}