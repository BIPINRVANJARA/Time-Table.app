import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/subject.dart';
import '../models/user_model.dart';
import 'faculty_service.dart';
import '../models/faculty.dart';


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
    final user = _auth.currentUser;
    
    if (user == null) {
      // Check for local faculty session (Special case for out-of-sync auth)
      return Stream.fromFuture(FacultyService.getLocalSessionId()).asyncExpand((facultyId) {
        if (facultyId == null) return Stream.value(null);
        
        // Return a virtual user profile based on faculty document
        return _db
            .collection('faculty')
            .where('facultyId', isEqualTo: facultyId)
            .limit(1)
            .snapshots()
            .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          final facultyData = Faculty.fromFirestore(snapshot.docs.first);
          
          return UserModel(
            uid: facultyData.id,
            email: facultyData.email ?? '',
            role: facultyData.role,
            branch: '', // Not applicable for faculty
            semester: '',
            division: '',
            batch: '',
            facultyId: facultyData.facultyId,
            createdAt: facultyData.createdAt,
          );
        });
      });
    }

    return _db.collection('users').doc(user.uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data() as Map<String, dynamic>, user.uid);
    });
  }

  // Get current user profile (One-time)
  static Future<UserModel?> getUserProfile() async {
    final user = _auth.currentUser;
    
    if (user == null) {
       final facultyId = await FacultyService.getLocalSessionId();
       if (facultyId == null) return null;

       final query = await _db
            .collection('faculty')
            .where('facultyId', isEqualTo: facultyId)
            .limit(1)
            .get();
        
        if (query.docs.isEmpty) return null;
        final facultyData = Faculty.fromFirestore(query.docs.first);
        
        return UserModel(
          uid: facultyData.id,
          email: facultyData.email ?? '',
          role: facultyData.role,
          branch: '',
          semester: '',
          division: '',
          batch: '',
          facultyId: facultyData.facultyId,
          createdAt: facultyData.createdAt,
        );
    }

    final doc = await _db.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;

    return UserModel.fromMap(doc.data() as Map<String, dynamic>, user.uid);
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

  // Stream all timetables (for faculty to see all their lectures)
  // This uses a collection group query which requires an index in Firestore
  static Stream<List<Subject>> streamAllTimetables() {
    return _db
        .collectionGroup('subjects')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Subject.fromFirestore(doc))
          .toList();
    });
  }

  // Assign a proxy to a subject
  static Future<void> assignProxy(Subject subject, String proxyFacultyId, String proxyFacultyName, String originalFacultyName) async {
    // If we have a direct reference, use it (Best Practice)
    if (subject.reference != null) {
      await subject.reference!.update({
        'proxyFacultyId': proxyFacultyId,
        'isProxy': true,
        'originalFacultyName': originalFacultyName,
        'facultyName': '$originalFacultyName (Proxy: $proxyFacultyName)',
        'facultyId': proxyFacultyId,
      });
      return;
    }

    // Fallback: Find the subject document using collection group query
    // NOTE: This might fail if subjectId is just an ID string and not a path.
    // It's safer to rely on reference.
    final query = _db.collectionGroup('subjects').where(FieldPath.documentId, isEqualTo: subject.id);
    final snapshot = await query.get();
    
    if (snapshot.docs.isEmpty) {
      throw Exception('Subject not found');
    }
    
    // Update the first matching document (IDs should be unique)
    final docRef = snapshot.docs.first.reference;
    
    await docRef.update({
      'proxyFacultyId': proxyFacultyId,
      'isProxy': true,
      'originalFacultyName': originalFacultyName,
      // We also update the facultyName to show the proxy faculty
      'facultyName': '$originalFacultyName (Proxy: $proxyFacultyName)',
      'facultyId': proxyFacultyId, // Reassign to proxy faculty so they see it in their schedule
    });
  }

  // --- Personal Subjects (Faculty Only) ---

  // Add a personal subject
  static Future<void> addPersonalSubject(String facultyId, Subject subject) async {
    final ref = _db
        .collection('faculty')
        .doc(facultyId)
        .collection('personal_subjects')
        .doc();
    
    subject.id = ref.id;
    subject.isPersonal = true;
    await ref.set(subject.toMap());
  }

  // Delete a personal subject
  static Future<void> deletePersonalSubject(String facultyId, String subjectId) async {
    await _db
        .collection('faculty')
        .doc(facultyId)
        .collection('personal_subjects')
        .doc(subjectId)
        .delete();
  }

  // Stream personal subjects
  static Stream<List<Subject>> streamPersonalSubjects(String facultyId) {
    return _db
        .collection('faculty')
        .doc(facultyId)
        .collection('personal_subjects')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Subject.fromFirestore(doc))
          .toList();
    });
  }

  // --- Warning Methods ---

  // Send a warning to a student
  static Future<void> sendWarning(String studentUid, String facultyName, String message) async {
    await _db
        .collection('users')
        .doc(studentUid)
        .collection('warnings')
        .add({
      'facultyName': facultyName,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });
  }

  // Stream warnings for a student
  static Stream<List<Map<String, dynamic>>> streamWarnings(String studentUid) {
    return _db
        .collection('users')
        .doc(studentUid)
        .collection('warnings')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }
}

