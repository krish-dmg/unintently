import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/assignment_doc.dart';

class LocalStorageService {
  static const String _assignmentsKey = 'unintently_docs_v2';

  static Future<void> saveDoc(AssignmentDoc doc) async {
    final prefs = await SharedPreferences.getInstance();
    final List<AssignmentDoc> list = await getDocs();
    final idx = list.indexWhere((d) => d.id == doc.id);
    if (idx >= 0) {
      list[idx] = doc;
    } else {
      list.insert(0, doc);
    }
    final raw = list.map((d) => d.toMap()).toList();
    await prefs.setString(_assignmentsKey, json.encode(raw));
  }

  static Future<List<AssignmentDoc>> getDocs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_assignmentsKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final List<dynamic> decoded = json.decode(jsonStr);
      return decoded.map((m) => AssignmentDoc.fromMap(m as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> deleteDoc(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final List<AssignmentDoc> list = await getDocs();
    list.removeWhere((d) => d.id == id);
    final raw = list.map((d) => d.toMap()).toList();
    await prefs.setString(_assignmentsKey, json.encode(raw));
  }

  static Future<AssignmentDoc?> getDocById(String id) async {
    final list = await getDocs();
    try {
      return list.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }
}
