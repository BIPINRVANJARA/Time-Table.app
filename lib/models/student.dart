import 'package:cloud_firestore/cloud_firestore.dart';

class Student {
  String id;
  int srNumber;
  String name;
  String enrollmentNumber;
  String semester;
  String division;
  String batch;
  String? linkedEmail; // Optional: link student account for self-tracking

  Student({
    required this.id,
    required this.srNumber,
    required this.name,
    required this.enrollmentNumber,
    required this.semester,
    required this.division,
    required this.batch,
    this.linkedEmail,
  });

  factory Student.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Student(
      id: doc.id,
      srNumber: data['srNumber'] ?? 0,
      name: data['name'] ?? '',
      enrollmentNumber: data['enrollmentNumber'] ?? '',
      semester: data['semester'] ?? '',
      division: data['division'] ?? '',
      batch: data['batch'] ?? '',
      linkedEmail: data['linkedEmail'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'srNumber': srNumber,
      'name': name,
      'enrollmentNumber': enrollmentNumber,
      'semester': semester,
      'division': division,
      'batch': batch,
      'linkedEmail': linkedEmail,
    };
  }

  Student copyWith({
    String? id,
    int? srNumber,
    String? name,
    String? enrollmentNumber,
    String? semester,
    String? division,
    String? batch,
    String? linkedEmail,
  }) {
    return Student(
      id: id ?? this.id,
      srNumber: srNumber ?? this.srNumber,
      name: name ?? this.name,
      enrollmentNumber: enrollmentNumber ?? this.enrollmentNumber,
      semester: semester ?? this.semester,
      division: division ?? this.division,
      batch: batch ?? this.batch,
      linkedEmail: linkedEmail ?? this.linkedEmail,
    );
  }
}
