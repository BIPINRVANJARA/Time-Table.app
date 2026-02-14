class UserModel {
  final String uid;
  final String email;
  final String role; // 'student', 'admin', or 'faculty'
  final String branch;
  final String semester;
  final String division;
  final String batch;
  final String? facultyId; // Faculty ID if role is 'faculty'
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    required this.branch,
    required this.semester,
    required this.division,
    required this.batch,
    this.facultyId,
    required this.createdAt,
  });

  // Create a UserModel from a Map (Firestore data)
  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      role: data['role'] ?? 'student',
      branch: data['branch'] ?? '',
      semester: data['semester'] ?? '',
      division: data['division'] ?? '',
      batch: data['batch'] ?? '',
      facultyId: data['facultyId'],
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as dynamic).toDate() 
          : DateTime.now(),
    );
  }

  // Convert UserModel to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'role': role,
      'branch': branch,
      'semester': semester,
      'division': division,
      'batch': batch,
      'facultyId': facultyId,
      // createdAt is usually set by serverTimestamp on creation, so we might skip it here on updates
    };
  }
}
