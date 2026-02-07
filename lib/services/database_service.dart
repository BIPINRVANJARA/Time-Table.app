import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/subject.dart';
import '../models/user_model.dart';


class DatabaseService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;



  // --- User Profile Methods ---

  // Save/Update User Profile (Academic Setup)
  static Future<void> updateUserProfile(UserModel userModel) async {
    await _db.collection('users').doc(userModel.uid).set(
      userModel.toMap(),
      SetOptions(merge: true),
    );
  }

  // Stream current user profile (Reactive)
  static Stream<UserModel?> streamUserProfile() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(null);

    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data() as Map<String, dynamic>, uid);
    });
  }

  // Get current user profile (One-time)
  static Future<UserModel?> getUserProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;

    return UserModel.fromMap(doc.data() as Map<String, dynamic>, uid);
  }

  // --- Timetable Methods (Firestore) ---

  // Add a new subject (Admin only path)
  static Future<void> addSubject(
      String branch, String semester, String division, Subject subject) async {
    final docId = '${branch}_${semester}_${division}'.replaceAll(' ', '');
    final ref = _db
        .collection('timetables')
        .doc(docId)
        .collection('subjects')
        .doc(); // Auto-generate ID if not provided
    
    subject.id = ref.id; // Assign the generated ID to the subject object
    await ref.set(subject.toMap());
  }

  // Update an existing subject (Admin only path)
  static Future<void> updateSubject(
      String branch, String semester, String division, Subject subject) async {
    final docId = '${branch}_${semester}_${division}'.replaceAll(' ', '');
    await _db
        .collection('timetables')
        .doc(docId)
        .collection('subjects')
        .doc(subject.id)
        .update(subject.toMap());
  }

  // Delete a subject (Admin only path)
  static Future<void> deleteSubject(
      String branch, String semester, String division, String subjectId) async {
    final docId = '${branch}_${semester}_${division}'.replaceAll(' ', '');
    await _db
        .collection('timetables')
        .doc(docId)
        .collection('subjects')
        .doc(subjectId)
        .delete();
  }

  // Stream timetable based on academic details
  // branches/{branch}/semesters/{sem}/divisions/{div}/timetable
  static Stream<List<Subject>> streamTimetable(
      String branch, String semester, String division) {
    
    // Note: This path structure assumes the hierarchy:
    // colleges/default/branches/Computer/semesters/1/divisions/A/timetable/subjectId
    // For simplicity in this demo, let's use a flatter structure if possible, 
    // OR we stick to the plan:
    // root -> timetables -> {structure_id} -> subjects
    
    // Let's us a query based approach for simplicity first:
    // collection: 'timetables'
    // fields: branch, semester, division
    
    // Actually, the plan suggested: College > Branch > Sem...
    // Let's construct the path dynamically.
    // For now, let's assume we store subjects in a root collection 'subjects' 
    // and query them (this might be easier to manage than deep nesting for now).
    // NO, deep nesting is better for read security rules.
    
    // Path: timetables (collection) -> {branch}_{sem}_{div} (doc) -> subjects (subcollection)
    final docId = '${branch}_${semester}_${division}'.replaceAll(' ', '');
    
    return _db
        .collection('timetables')
        .doc(docId)
        .collection('subjects')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Subject.fromFirestore(doc))
          .toList();
    });
  }

  // Temporary helper to keep main.dart compiling
  static bool hasSubjects() {
    // This previously checked local storage. 
    // Now we rely on Auth + Academic Setup status.
    // We can't synchronously check Firestore.
    // We should return true/false based on if the user has completed setup.
    // For now, let's return false so we force checks elsewhere.
    return false; 
  }
}

