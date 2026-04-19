import 'package:cloud_firestore/cloud_firestore.dart';

class Faculty {
  String id;
  String facultyId; // Unique ID like "FAC001"
  String facultyName;
  String passwordHash;
  String? department;
  String? email;
  DateTime createdAt;
  String role;
  String? uid;

  Faculty({
    required this.id,
    required this.facultyId,
    required this.facultyName,
    required this.passwordHash,
    this.department,
    this.email,
    required this.createdAt,
    this.role = 'faculty', // 'faculty' or 'faculty_admin'
    this.uid, // Firebase Auth UID
  });

  // Factory to create from Firestore document
  factory Faculty.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Faculty(
      id: doc.id,
      facultyId: data['facultyId'] ?? '',
      facultyName: data['facultyName'] ?? '',
      passwordHash: data['passwordHash'] ?? '',
      department: data['department'],
      email: data['email'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      role: data['role'] ?? 'faculty',
      uid: data['uid'],
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'facultyId': facultyId,
      'facultyName': facultyName,
      'passwordHash': passwordHash,
      'department': department,
      'email': email,
      'createdAt': Timestamp.fromDate(createdAt),
      'role': role,
      'uid': uid,
    };
  }

  // Helper to create from form data (without password hash)
  factory Faculty.create({
    required String facultyId,
    required String facultyName,
    String? department,
    String? email,
  }) {
    return Faculty(
      id: '',
      facultyId: facultyId,
      facultyName: facultyName,
      passwordHash: '', // Will be set during creation
      department: department,
      email: email,
      createdAt: DateTime.now(),
      role: 'faculty',
    );
  }
}
