import 'package:cloud_firestore/cloud_firestore.dart';

class Subject {
  String id;
  String subjectName;
  String facultyName;
  String type; // 'lecture' or 'lab'
  int dayOfWeek; // 1=Monday, 7=Sunday
  int startHour;
  int startMinute;
  int endHour;
  int endMinute;
  bool reminderEnabled;
  int reminderMinutesBefore;
  int? colorValue; // ARGB value
  String? batch; // Specific batch (e.g., A1, B1) or null for all
  String? facultyId; // Faculty ID assigned to this lecture
  String? roomNumber; // Room number where lecture is held
  bool isPersonal; // Personal subject for faculty (not visible to students)


  Subject({
    required this.id,
    required this.subjectName,
    this.facultyName = '',
    this.type = 'lecture',
    required this.dayOfWeek,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    this.reminderEnabled = false,
    this.reminderMinutesBefore = 5,
    this.colorValue,
    this.batch,
    this.facultyId,
    this.roomNumber,
    this.isPersonal = false,
  });

  // Factory to create from Firestore document
  factory Subject.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Subject(
      id: doc.id,
      subjectName: data['subjectName'] ?? '',
      facultyName: data['facultyName'] ?? '',
      type: data['type'] ?? 'lecture',
      dayOfWeek: data['dayOfWeek'] ?? 1,
      startHour: data['startHour'] ?? 9,
      startMinute: data['startMinute'] ?? 0,
      endHour: data['endHour'] ?? 10,
      endMinute: data['endMinute'] ?? 0,
      reminderEnabled: data['reminderEnabled'] ?? false,
      reminderMinutesBefore: data['reminderMinutesBefore'] ?? 5,
      colorValue: data['colorValue'],
      batch: data['batch'],
      facultyId: data['facultyId'],
      roomNumber: data['roomNumber'],
      isPersonal: data['isPersonal'] ?? false,
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'subjectName': subjectName,
      'facultyName': facultyName,
      'type': type,
      'dayOfWeek': dayOfWeek,
      'startHour': startHour,
      'startMinute': startMinute,
      'endHour': endHour,
      'endMinute': endMinute,
      'reminderEnabled': reminderEnabled,
      'reminderMinutesBefore': reminderMinutesBefore,
      'colorValue': colorValue,
      'batch': batch,
      'facultyId': facultyId,
      'roomNumber': roomNumber,
      'isPersonal': isPersonal,
    };
  }

  // Helpers
  DateTime get startTime {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, startHour, startMinute);
  }
  
  DateTime get endTime {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, endHour, endMinute);
  }

  String get timeRange {
    String formatTime(int hour, int minute) {
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
    }
    return '${formatTime(startHour, startMinute)} - ${formatTime(endHour, endMinute)}';
  }

  int get startInMinutes => (startHour * 60) + startMinute;
}

