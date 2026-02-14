import 'package:cloud_firestore/cloud_firestore.dart';

class Faculty {
  String id;
  String facultyId; // Unique ID like "FAC001"
  String facultyName;
  String passwordHash;
  String? department;
  String? email;
  DateTime createdAt;

  Faculty({
    required this.id,
    required this.facultyId,
    required this.facultyName,
    required this.passwordHash,
    this.department,
    this.email,
    required this.createdAt,
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
    );
  }
}
