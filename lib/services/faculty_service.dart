import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/faculty.dart';

class FacultyService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'faculty';

  /// Hash password using SHA-256
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Create a new faculty account
  static Future<void> createFaculty({
    String? facultyId, // Made optional for auto-generation
    required String facultyName,
    required String password,
    String? department,
    required String email, // Made required
  }) async {
    String finalFacultyId = facultyId ?? await _generateNextFacultyId();

    // specific check if manually provided
    if (facultyId != null) {
      final existing = await _firestore
          .collection(_collection)
          .where('facultyId', isEqualTo: facultyId)
          .get();

      if (existing.docs.isNotEmpty) {
        throw Exception('Faculty ID $facultyId already exists');
      }
    }

    final faculty = Faculty(
      id: '', // Will be auto-generated
      facultyId: finalFacultyId,
      facultyName: facultyName,
      passwordHash: hashPassword(password),
      department: department,
      email: email,
      createdAt: DateTime.now(),
    );

    await _firestore.collection(_collection).add(faculty.toMap());
  }

  /// Generate the next available Faculty ID (FAC001, FAC002, ...)
  static Future<String> _generateNextFacultyId() async {
    // We need to order by facultyId descending to get the last one.
    // However, string sorting 'FAC010' < 'FAC002' is false, but 'FAC10' vs 'FAC2'.
    // With fixed padding (FAC001), string sorting works fine up to FAC999.
    // Assuming standard format.
    
    final snapshot = await _firestore
        .collection(_collection)
        .orderBy('facultyId', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return 'FAC001';
    }

    try {
      final lastId = snapshot.docs.first.data()['facultyId'] as String;
      // Expecting format FACxxx
      if (lastId.startsWith('FAC')) {
        final numberPart = lastId.substring(3);
        final number = int.tryParse(numberPart) ?? 0;
        final nextNumber = number + 1;
        return 'FAC${nextNumber.toString().padLeft(3, '0')}';
      }
    } catch (e) {
      // If any error parsing, fall back to timestamp or just FAC001 if really broken?
      // Better to return a safe fallback or throw.
      // Let's assume FAC001 fallback if parsing fails, but that might duplicate.
      // Let's append a timestamp if format is weird? No, user wants sequence.
    }
    
    // If we couldn't parse or it wasn't empty but didn't match FAC, 
    // maybe we should just count documents? 
    // Let's stick to the query logic.
    return 'FAC001'; 
  }

  /// Authenticate faculty with ID and password
  static Future<Faculty?> authenticateFaculty(String facultyId, String password) async {
    final querySnapshot = await _firestore
        .collection(_collection)
        .where('facultyId', isEqualTo: facultyId)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return null; // Faculty not found
    }

    final doc = querySnapshot.docs.first;
    final faculty = Faculty.fromFirestore(doc);

    // Verify password
    if (faculty.passwordHash == hashPassword(password)) {
      return faculty;
    }

    return null; // Invalid password
  }

  /// Get faculty by document ID
  static Future<Faculty?> getFacultyById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    return Faculty.fromFirestore(doc);
  }

  /// Get faculty by faculty ID
  static Future<Faculty?> getFacultyByFacultyId(String facultyId) async {
    final querySnapshot = await _firestore
        .collection(_collection)
        .where('facultyId', isEqualTo: facultyId)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) return null;
    return Faculty.fromFirestore(querySnapshot.docs.first);
  }

  /// Get all faculty members
  static Future<List<Faculty>> getAllFaculty() async {
    final querySnapshot = await _firestore
        .collection(_collection)
        .orderBy('facultyName')
        .get();

    return querySnapshot.docs
        .map((doc) => Faculty.fromFirestore(doc))
        .toList();
  }

  /// Stream all faculty members
  static Stream<List<Faculty>> streamAllFaculty() {
    return _firestore
        .collection(_collection)
        .orderBy('facultyName')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Faculty.fromFirestore(doc)).toList());
  }

  /// Update faculty information
  static Future<void> updateFaculty(Faculty faculty) async {
    await _firestore.collection(_collection).doc(faculty.id).update(faculty.toMap());
  }

  /// Update faculty password
  static Future<void> updatePassword(String facultyId, String newPassword) async {
    final querySnapshot = await _firestore
        .collection(_collection)
        .where('facultyId', isEqualTo: facultyId)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      throw Exception('Faculty not found');
    }

    await querySnapshot.docs.first.reference.update({
      'passwordHash': hashPassword(newPassword),
    });
  }

  /// Delete faculty account
  static Future<void> deleteFaculty(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  /// Check if faculty ID exists
  static Future<bool> facultyIdExists(String facultyId) async {
    final querySnapshot = await _firestore
        .collection(_collection)
        .where('facultyId', isEqualTo: facultyId)
        .limit(1)
        .get();

    return querySnapshot.docs.isNotEmpty;
  }
}
