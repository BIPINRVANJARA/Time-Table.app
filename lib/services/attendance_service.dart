import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/attendance_record.dart';
import '../models/student.dart';
import 'student_service.dart';
import 'package:intl/intl.dart';

class AttendanceService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Get the Firestore group document ID
  static String _groupId(String semester, String division, String batch) {
    final s = semester.replaceAll(RegExp(r'[^0-9]'), '');
    final d = division.trim().toUpperCase();
    final b = batch.trim(); // Keep batch case as is to match "All", "B1" etc.
    return '${s}_${d}_$b'.replaceAll(' ', '');
  }

  /// Normalize semester string (e.g. "Semester 4" -> "4")
  static String normalizeSemester(String semester) {
    return semester.replaceAll(RegExp(r'[^0-9]'), '');
  }

  /// Normalize division string
  static String normalizeDivision(String division) {
    return division.trim().toUpperCase();
  }

  /// Save attendance for a specific date and subject
  static Future<void> saveAttendance(AttendanceRecord record) async {
    final groupId = _groupId(record.semester, record.division, record.batch);

    await _db
        .collection('attendance')
        .doc(groupId)
        .collection('subjects')
        .doc(record.subjectId)
        .collection('dates')
        .doc(record.date)
        .set(record.toMap());
  }

  /// Get attendance for a specific date and subject
  static Future<AttendanceRecord?> getAttendance(
    String semester,
    String division,
    String batch,
    String subjectId,
    String date,
  ) async {
    final groupId = _groupId(semester, division, batch);

    final doc = await _db
        .collection('attendance')
        .doc(groupId)
        .collection('subjects')
        .doc(subjectId)
        .collection('dates')
        .doc(date)
        .get();

    if (!doc.exists) return null;
    return AttendanceRecord.fromFirestore(doc);
  }

  /// Mark a day as holiday for a subject
  static Future<void> markHoliday(
    String semester,
    String division,
    String batch,
    String subjectId,
    String subjectName,
    String date,
    String facultyId,
  ) async {
    final record = AttendanceRecord(
      date: date,
      subjectId: subjectId,
      subjectName: subjectName,
      semester: semester,
      division: division,
      batch: batch,
      isHoliday: true,
      records: {},
      facultyId: facultyId,
      markedAt: DateTime.now(),
    );
    await saveAttendance(record);
  }

  /// Get all attendance dates for a subject (to build export)
  static Future<List<AttendanceRecord>> getAllAttendanceForSubject(
    String semester,
    String division,
    String batch,
    String subjectId, {
    String? startDate,
    String? endDate,
  }) async {
    final groupId = _groupId(semester, division, batch);

    var query = _db
        .collection('attendance')
        .doc(groupId)
        .collection('subjects')
        .doc(subjectId)
        .collection('dates')
        .orderBy(FieldPath.documentId);

    if (startDate != null) {
      query = query.where(FieldPath.documentId, isGreaterThanOrEqualTo: startDate);
    }
    if (endDate != null) {
      query = query.where(FieldPath.documentId, isLessThanOrEqualTo: endDate);
    }

    final snapshot = await query.get();

    return snapshot.docs
        .map((doc) => AttendanceRecord.fromFirestore(doc))
        .toList();
  }

  /// Export attendance as CSV string
  /// Rows: students, Columns: dates
  static Future<String> exportAttendanceCSV(
    String subjectType,
    String semester,
    String division,
    String batch,
    String subjectId,
    String subjectName, {
    String? startDate,
    String? endDate,
  }) async {
    // 1. Get all students
    final isLecture = subjectType == 'lecture' || batch == 'All' || batch == 'ALL';
    final students = isLecture
        ? await StudentService.getAllStudentsInDivision(semester, division)
        : await StudentService.getStudents(semester, division, batch);

    // 2. Get attendance records for range
    final records = await getAllAttendanceForSubject(
      semester,
      division,
      batch,
      subjectId,
      startDate: startDate,
      endDate: endDate,
    );

    if (records.isEmpty) {
      return 'No attendance records found.';
    }

    // 3. Build CSV
    final buffer = StringBuffer();

    // Header: Subject info
    buffer.writeln('Subject: $subjectName');
    buffer.writeln("Type: \${subjectType.toUpperCase()} | Semester: $semester | Division: $division \${subjectType == 'lab' ? '| Batch: $batch' : ''}");
    if (startDate != null && endDate != null) {
      buffer.writeln('Duration: $startDate to $endDate');
    }
    buffer.writeln('');

    // Column headers
    final dates = records.map((r) => r.date).toList();
    buffer.write('Sr No,Name,Enrollment No');
    for (final date in dates) {
      // Check if holiday
      final rec = records.firstWhere((r) => r.date == date);
      buffer.write(',${rec.isHoliday ? "$date (Holiday)" : date}');
    }
    buffer.write(',Total Present,Total Absent,Percentage');
    buffer.writeln();

    // Student rows
    for (final student in students) {
      int present = 0;
      int absent = 0;
      int totalLectures = 0;

      buffer.write('${student.srNumber},${student.name},${student.enrollmentNumber}');

      for (final record in records) {
        if (record.isHoliday) {
          buffer.write(',H');
        } else {
          totalLectures++;
          final isPresent = record.records[student.enrollmentNumber] ?? false;
          if (isPresent) {
            present++;
            buffer.write(',P');
          } else {
            absent++;
            buffer.write(',A');
          }
        }
      }

      final percentage = totalLectures > 0
          ? (present / totalLectures * 100).toStringAsFixed(1)
          : '0.0';
      buffer.write(',$present,$absent,$percentage%');
      buffer.writeln();
    }

    // Summary row
    buffer.writeln();
    buffer.write('Daily Total Present,,');
    for (final record in records) {
      if (record.isHoliday) {
        buffer.write(',Holiday');
      } else {
        buffer.write(',${record.totalPresent}');
      }
    }
    buffer.writeln();

    buffer.write('Daily Total Absent,,');
    for (final record in records) {
      if (record.isHoliday) {
        buffer.write(',Holiday');
      } else {
        buffer.write(',${record.totalAbsent}');
      }
    }
    buffer.writeln();

    // Export date
    buffer.writeln();
    buffer.writeln('Exported on: ${DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now())}');

    return buffer.toString();
  }

  /// Get attendance statistics for a specific student across all subjects
  static Future<Map<String, dynamic>> getStudentAttendanceStats(
    String enrollmentNumber,
    String semester,
    String division,
    String batch,
  ) async {
    final groupId = _groupId(semester, division, batch);
    final lectureGroupId = _groupId(semester, division, ''); // For lectures, batch is often ignored or group is different

    // We need to fetch all attendance records for this group
    // This is tricky because subjects are subcollections.
    // We'll use a collection group query for 'dates' and filter by groupId in the path or document data.
    
    // To make it efficient, we assume each attendance record document contains 
    // metadata for filtering. AttendanceRecord.toMap() includes semester, division, batch.
    
    // Normalize inputs
    final semNum = normalizeSemester(semester);
    final divNorm = normalizeDivision(division);
    final enrollmentNorm = enrollmentNumber.trim();
    
    // Variations for legacy data compatibility
    final semesterVariations = [
      semNum,
      semester.trim(),
      "Semester $semNum",
      "Sem $semNum",
      "Semester$semNum",
      "Sem$semNum"
    ].toSet().toList(); // Remove duplicates

    try {
      final query = _db.collectionGroup('dates')
          .where('semester', whereIn: semesterVariations)
          .where('division', isEqualTo: divNorm);
          
      final snapshot = await query.get();
      
      int totalLectures = 0;
      int totalPresent = 0;
    Map<String, Map<String, dynamic>> subjectStats = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final recordBatch = data['batch'] as String?;
      
      // Filter by batch: 
      // 1. If the record is for 'All' (Lecture), everyone in the division is included.
      // 2. If it's a specific batch (Lab), only students in that batch are included.
      bool batchMatches = false;
      if (recordBatch == null || recordBatch.isEmpty || recordBatch == 'All' || recordBatch == 'ALL') {
        batchMatches = true;
      } else if (recordBatch == batch) {
        batchMatches = true;
      }

      if (!batchMatches) continue;
      
      if (data['isHoliday'] == true) continue;

      final subjectId = data['subjectId'] as String;
      final subjectName = data['subjectName'] as String;
      final records = data['records'] as Map<String, dynamic>? ?? {};
      
      totalLectures++;
      final isPresent = records[enrollmentNorm] == true;
      if (isPresent) totalPresent++;

      if (!subjectStats.containsKey(subjectId)) {
        subjectStats[subjectId] = {
          'name': subjectName,
          'present': 0,
          'total': 0,
        };
      }
      
      subjectStats[subjectId]!['total']++;
      if (isPresent) subjectStats[subjectId]!['present']++;
    }

    final overallPercentage = totalLectures > 0 
        ? (totalPresent / totalLectures * 100) 
        : 0.0;

      return {
        'overallPercentage': overallPercentage,
        'totalPresent': totalPresent,
        'totalLectures': totalLectures,
        'subjectStats': subjectStats,
      };
    } catch (e) {
      if (e.toString().contains('requires an index')) {
        rethrow;
      }
      return {
        'overallPercentage': 0.0,
        'totalPresent': 0,
        'totalLectures': 0,
        'subjectStats': {},
      };
    }
  }

  /// Stream all attendance records marked by a specific faculty
  static Stream<List<AttendanceRecord>> streamFacultyAttendanceRecords(String facultyId) {
    return _db.collectionGroup('dates')
        .where('facultyId', isEqualTo: facultyId)
        .orderBy('markedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AttendanceRecord.fromFirestore(doc))
          .toList();
    });
  }

  /// Helper to calculate overall statistics from a list of records
  static Map<String, dynamic> aggregateDashboardStats(List<AttendanceRecord> records, {double riskThreshold = 0.75}) {
    if (records.isEmpty) {
      return {
        'totalClasses': 0,
        'atRiskCount': 0,
        'subjectStats': {},
        'atRiskStudents': [],
      };
    }

    Map<String, Map<String, dynamic>> subjectStats = {};
    Map<String, Map<String, int>> studentAggregates = {}; // enrollment -> {present, total}

    for (var record in records) {
      // Aggressive Normalization: 
      // 1. Remove Batch codes (e.g., B1-, B3-)
      // 2. Remove Parenthesis and their contents (e.g., (AJB))
      // 3. Remove Room codes (e.g., -306B)
      // 4. Remove all non-alphanumeric symbols
      String cleanName = record.subjectName
          .replaceAll(RegExp(r'B[0-9]-'), '')             // Strips B1-, B2-
          .replaceAll(RegExp(r'\([^)]*\)'), '')            // Strips (AJB)
          .replaceAll(RegExp(r'-[0-9]{3}[A-Z]?'), '')     // Strips -306B
          .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')        // Strips all dots, dashes, spaces
          .trim()
          .toUpperCase();
      
      // Fallback if cleaning results in empty string
      if (cleanName.isEmpty) cleanName = record.subjectName.toUpperCase();

      // Creating a key that groups the same subject across a specific division
      final subjectKey = '${record.semester}_${record.division}_$cleanName';
      
      if (!subjectStats.containsKey(subjectKey)) {
        subjectStats[subjectKey] = {
          'name': record.subjectName,
          'semester': record.semester,
          'division': record.division,
          'lectureRecords': <AttendanceRecord>[],
          'labBatches': <String, List<AttendanceRecord>>{},
        };
      }
      
      final sStat = subjectStats[subjectKey]!;
      final isLecture = record.batch.isEmpty || record.batch == 'All' || record.batch == 'ALL';
      
      if (isLecture) {
        (sStat['lectureRecords'] as List<AttendanceRecord>).add(record);
      } else {
        final labs = sStat['labBatches'] as Map<String, List<AttendanceRecord>>;
        if (!labs.containsKey(record.batch)) labs[record.batch] = [];
        labs[record.batch]!.add(record);
      }

      // Safe Student Aggregation
      if (!record.isHoliday) {
        record.records.forEach((enrollment, isPresent) {
          final stats = studentAggregates.putIfAbsent(enrollment, () => {'present': 0, 'total': 0});
          stats['total'] = (stats['total'] ?? 0) + 1;
          if (isPresent == true) {
            stats['present'] = (stats['present'] ?? 0) + 1;
          }
        });
      }
    }

    // Process At-Risk Students
    List<Map<String, dynamic>> atRiskList = [];
    studentAggregates.forEach((enrollment, data) {
      final total = data['total'] ?? 0;
      final present = data['present'] ?? 0;
      if (total >= 2) {
        final percentage = present / total;
        if (percentage < riskThreshold) {
          atRiskList.add({
            'enrollment': enrollment,
            'present': present,
            'total': total,
            'percentage': percentage,
          });
        }
      }
    });

    atRiskList.sort((a, b) => (a['percentage'] as double).compareTo(b['percentage'] as double));

    return {
      'totalClasses': records.length,
      'atRiskCount': atRiskList.length,
      'subjectStats': subjectStats,
      'atRiskStudents': atRiskList,
    };
  }
}
