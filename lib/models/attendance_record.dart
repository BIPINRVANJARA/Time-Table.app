import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceRecord {
  String date; // yyyy-MM-dd
  String subjectId;
  String subjectName;
  String semester;
  String division;
  String batch;
  bool isHoliday;
  Map<String, bool> records; // enrollmentNumber -> present(true)/absent(false)
  String facultyId;
  DateTime markedAt;

  AttendanceRecord({
    required this.date,
    required this.subjectId,
    required this.subjectName,
    required this.semester,
    required this.division,
    required this.batch,
    this.isHoliday = false,
    required this.records,
    required this.facultyId,
    required this.markedAt,
  });

  factory AttendanceRecord.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // Parse records map
    Map<String, bool> parsedRecords = {};
    if (data['records'] != null) {
      (data['records'] as Map<String, dynamic>).forEach((key, value) {
        parsedRecords[key] = value as bool;
      });
    }

    return AttendanceRecord(
      date: doc.id, // Document ID is the date
      subjectId: data['subjectId'] ?? '',
      subjectName: data['subjectName'] ?? '',
      semester: data['semester'] ?? '',
      division: data['division'] ?? '',
      batch: data['batch'] ?? '',
      isHoliday: data['isHoliday'] ?? false,
      records: parsedRecords,
      facultyId: data['facultyId'] ?? '',
      markedAt: (data['markedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subjectId': subjectId,
      'subjectName': subjectName,
      'semester': semester,
      'division': division,
      'batch': batch,
      'isHoliday': isHoliday,
      'records': records,
      'facultyId': facultyId,
      'markedAt': Timestamp.fromDate(markedAt),
    };
  }

  int get totalPresent => records.values.where((v) => v == true).length;
  int get totalAbsent => records.values.where((v) => v == false).length;
  int get totalStudents => records.length;
}
