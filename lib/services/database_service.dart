import 'package:hive_flutter/hive_flutter.dart';
import '../models/subject.dart';

class DatabaseService {
  static const String _subjectsBoxName = 'subjects';
  static Box<Subject>? _subjectsBox;

  // Initialize Hive and open boxes
  static Future<void> initialize() async {
    await Hive.initFlutter();
    Hive.registerAdapter(SubjectAdapter());
    _subjectsBox = await Hive.openBox<Subject>(_subjectsBoxName);
  }

  // Get the subjects box
  static Box<Subject> get subjectsBox {
    if (_subjectsBox == null || !_subjectsBox!.isOpen) {
      throw Exception('Subjects box is not initialized. Call initialize() first.');
    }
    return _subjectsBox!;
  }

  // Add a new subject
  static Future<void> addSubject(Subject subject) async {
    await subjectsBox.put(subject.id, subject);
  }

  // Update an existing subject
  static Future<void> updateSubject(Subject subject) async {
    await subjectsBox.put(subject.id, subject);
  }

  // Delete a subject
  static Future<void> deleteSubject(String id) async {
    await subjectsBox.delete(id);
  }

  // Get all subjects
  static List<Subject> getAllSubjects() {
    return subjectsBox.values.toList();
  }

  // Get subjects for a specific day (1=Monday, 7=Sunday)
  static List<Subject> getSubjectsByDay(int dayOfWeek) {
    final subjects = subjectsBox.values
        .where((subject) => subject.dayOfWeek == dayOfWeek)
        .toList();
    
    // Sort by start time using minutes since midnight
    // This is the ONLY correct way to sort times
    subjects.sort((a, b) => a.startInMinutes.compareTo(b.startInMinutes));
    
    return subjects;
  }

  // Get subjects for today
  static List<Subject> getTodaySubjects() {
    final today = DateTime.now().weekday;
    return getSubjectsByDay(today);
  }

  // Get a subject by ID
  static Subject? getSubjectById(String id) {
    return subjectsBox.get(id);
  }

  // Delete all subjects (for reset functionality)
  static Future<void> deleteAllSubjects() async {
    await subjectsBox.clear();
  }

  // Check if there are any subjects
  static bool hasSubjects() {
    return subjectsBox.isNotEmpty;
  }

  // Get count of subjects for a specific day
  static int getSubjectCountByDay(int dayOfWeek) {
    return subjectsBox.values
        .where((subject) => subject.dayOfWeek == dayOfWeek)
        .length;
  }
}
