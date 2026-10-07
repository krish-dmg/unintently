import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/assignment_model.dart';

class LocalStorageService {
  static const String _assignmentsKey = 'unintently_assignments_v2';

  /// Save or update an assignment in local storage
  static Future<void> saveAssignment(AssignmentModel assignment) async {
    final prefs = await SharedPreferences.getInstance();
    final List<AssignmentModel> current = await getAssignments();

    final index = current.indexWhere((item) => item.id == assignment.id);
    if (index >= 0) {
      current[index] = assignment;
    } else {
      current.insert(0, assignment);
    }

    final rawList = current.map((a) => a.toMap()).toList();
    await prefs.setString(_assignmentsKey, json.encode(rawList));
  }

  /// Get all assignments sorted by most recent
  static Future<List<AssignmentModel>> getAssignments() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_assignmentsKey);
    if (jsonStr == null || jsonStr.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decoded = json.decode(jsonStr);
      return decoded.map((m) => AssignmentModel.fromMap(m as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Delete an assignment by ID
  static Future<void> deleteAssignment(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final List<AssignmentModel> current = await getAssignments();
    current.removeWhere((item) => item.id == id);
    final rawList = current.map((a) => a.toMap()).toList();
    await prefs.setString(_assignmentsKey, json.encode(rawList));
  }

  /// Get single assignment by ID
  static Future<AssignmentModel?> getAssignmentById(String id) async {
    final list = await getAssignments();
    try {
      return list.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }
}
