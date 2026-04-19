import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student.dart';
import '../services/college_structure_service.dart';

class StudentService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static String _groupId(String semester, String division, String batch) {
    return '${semester}_${division}_$batch'.replaceAll(' ', '');
  }

  static List<String> _groupIdVariations(String semester, String division, String batch) {
    final raw = '${semester}_${division}_$batch';
    return [
      raw,                          // "Sem 4_B_B1"
      raw.replaceAll(' ', ''),      // "Sem4_B_B1"
      '${semester.replaceAll(' ', '')}_${division.trim()}_$batch', // "Sem4_B_B1"
    ];
  }

  /// Add a new student
  static Future<void> addStudent(
    String semester,
    String division,
    String batch,
    Student student,
  ) async {
    // We'll use the first variation as the default write path
    final targetId = _groupIdVariations(semester, division, batch).first;
    
    // Check for duplicate enrollment number
    final existing = await _db
        .collection('students')
        .doc(targetId)
        .collection('entries')
        .where('enrollmentNumber', isEqualTo: student.enrollmentNumber)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception(
          'A student with enrollment number ${student.enrollmentNumber} already exists in this group.');
    }

    final ref = _db
        .collection('students')
        .doc(targetId)
        .collection('entries')
        .doc();

    student.id = ref.id;
    await ref.set(student.toMap());
  }

  /// Remove a student
  static Future<void> removeStudent(
    String semester,
    String division,
    String batch,
    String studentId,
  ) async {
    // Try to find which path exists and delete from it
    for (var id in _groupIdVariations(semester, division, batch)) {
      final doc = await _db.collection('students').doc(id).get();
      if (doc.exists) {
        await _db.collection('students').doc(id).collection('entries').doc(studentId).delete();
        return;
      }
    }
  }

  /// Get all students in a group (one-time fetch)
  static Future<List<Student>> getStudents(
    String semester,
    String division,
    String batch,
  ) async {
    for (var id in _groupIdVariations(semester, division, batch)) {
      final snapshot = await _db
          .collection('students')
          .doc(id)
          .collection('entries')
          .orderBy('srNumber')
          .get();
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((doc) => Student.fromFirestore(doc)).toList();
      }
    }
    return [];
  }

  /// Get all students in an entire division across all batches (for Lectures)
  static Future<List<Student>> getAllStudentsInDivision(
    String semester,
    String division,
  ) async {
    final List<Student> allStudents = [];
    final batches = CollegeStructureService.getBatchesForDivision(division);
    final batchesToFetch = batches.isNotEmpty ? batches : ['${division}1', '${division}2', '${division}3', '${division}4', '${division}5', '${division}6'];

    for (var batchName in batchesToFetch) {
      try {
        final semNum = semester.replaceAll(RegExp(r'[^0-9]'), '');
        final variations = [
          ..._groupIdVariations(semNum, division, batchName),
          ..._groupIdVariations("Semester$semNum", division, batchName),
          ..._groupIdVariations("Sem$semNum", division, batchName),
          ..._groupIdVariations(semester, division, batchName),
        ].toSet().toList(); // Unique variations only

        QuerySnapshot? snapshot;
        for (var v in variations) {
          final query = _db.collection('students').doc(v).collection('entries').orderBy('srNumber');
          final candidate = await query.get();
          if (candidate.docs.isNotEmpty) {
            snapshot = candidate;
            break; 
          }
        }
        
        if (snapshot != null) {
          for (var doc in snapshot.docs) {
            allStudents.add(Student.fromFirestore(doc));
          }
        }
      } catch (e) {
        continue;
      }
    }
    return allStudents;
  }

  /// Stream students in a group (real-time)
  static Stream<List<Student>> streamStudents(
    String semester,
    String division,
    String batch,
  ) {
    // For streams, we just use the default path as standard
    return _db
        .collection('students')
        .doc(_groupId(semester, division, batch))
        .collection('entries')
        .orderBy('srNumber')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Student.fromFirestore(doc)).toList());
  }

  /// Promote all students from one semester to the next.
  /// Copies student entries from fromSemester → toSemester for ALL divisions and batches.
  /// Returns the number of students promoted.
  static Future<int> promoteStudents(String fromSemester) async {
    // Calculate "to" semester number
    final fromNum = int.tryParse(fromSemester.replaceAll(RegExp(r'[^0-9]'), ''));
    if (fromNum == null || fromNum < 1 || fromNum >= 8) {
      throw Exception('Invalid semester for promotion: $fromSemester');
    }
    final toSemester = (fromNum + 1).toString();

    final divisions = ['A', 'B', 'C'];
    final batchSuffixes = ['1', '2', '3'];
    int totalPromoted = 0;

    for (final div in divisions) {
      for (final suffix in batchSuffixes) {
        final batch = '$div$suffix';
        final fromGroupId = _groupId(fromSemester, div, batch);
        final toGroupId = _groupId(toSemester, div, batch);

        // Fetch all students from the source group
        final snapshot = await _db
            .collection('students')
            .doc(fromGroupId)
            .collection('entries')
            .get();

        if (snapshot.docs.isEmpty) continue;

        // Batch write to the destination group
        final writeBatch = _db.batch();
        for (final doc in snapshot.docs) {
          final data = doc.data();
          data['semester'] = toSemester; // Update semester number

          final newRef = _db
              .collection('students')
              .doc(toGroupId)
              .collection('entries')
              .doc(); // New doc ID in new group

          writeBatch.set(newRef, data);
          totalPromoted++;
        }
        await writeBatch.commit();
      }
    }

    return totalPromoted;
  }

  /// Bulk add students using WriteBatch
  static Future<int> bulkAddStudents(
    String semester,
    List<Map<String, dynamic>> studentsData,
  ) async {
    final writeBatch = _db.batch();
    int count = 0;

    for (final data in studentsData) {
      final division = data['division'] as String;
      final batch = data['batch'] as String;
      final srNo = data['sr_no'] as int;
      final name = data['name'] as String;
      final enrollmentNo = data['enrollment_no'] as String;

      final student = Student(
        id: '', // Will be set by Firestore
        srNumber: srNo,
        name: name,
        enrollmentNumber: enrollmentNo,
        semester: semester,
        division: division,
        batch: batch,
      );

      final groupId = _groupId(semester, division, batch);
      final ref = _db
          .collection('students')
          .doc(groupId)
          .collection('entries')
          .doc(); // Generate new ID

      writeBatch.set(ref, student.toMap());
      count++;
    }

    await writeBatch.commit();
    return count;
  }

  /// Update a single field on a student document
  static Future<void> updateStudentField(
    String semester,
    String division,
    String batch,
    String studentId,
    String field,
    dynamic value,
  ) async {
    await _db
        .collection('students')
        .doc(_groupId(semester, division, batch))
        .collection('entries')
        .doc(studentId)
        .update({field: value});
  }
}
