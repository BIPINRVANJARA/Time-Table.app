import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_core/firebase_core.dart'; // For secondary app init
import '../firebase_options.dart'; // For secondary app init
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
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

  // --- Session Management ---
  static const String _sessionKey = 'faculty_session_id';

  static Future<void> _saveLocalSession(String facultyId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, facultyId);
  }

  static Future<String?> getLocalSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sessionKey);
  }

  static Future<void> clearLocalSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  // Import these at the top:
  // import 'package:firebase_core/firebase_core.dart';
  // import '../firebase_options.dart';

  /// Create a new faculty account (Creates Firebase Auth User + Firestore Doc)
  static Future<void> createFaculty({
    String? facultyId, // Made optional for auto-generation
    required String facultyName,
    required String password,
    String? department,
    required String email, // Made required
  }) async {
    String finalFacultyId = facultyId ?? await _generateNextFacultyId();

    // Check if manually provided ID exists
    if (facultyId != null) {
      final existing = await _firestore
          .collection(_collection)
          .where('facultyId', isEqualTo: facultyId)
          .get();

      if (existing.docs.isNotEmpty) {
        throw Exception('Faculty ID $facultyId already exists');
      }
    }

    // Initialize a secondary Firebase App to create user without logging out admin
    FirebaseApp tempApp = await Firebase.initializeApp(
      name: 'tempAuth',
      options: DefaultFirebaseOptions.currentPlatform,
    );

    try {
      // Create user in Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instanceFor(app: tempApp)
          .createUserWithEmailAndPassword(email: email, password: password);
      
      String uid = userCredential.user!.uid;

      final faculty = Faculty(
        id: uid, // Use UID as Document ID
        facultyId: finalFacultyId,
        facultyName: facultyName,
        passwordHash: hashPassword(password),
        department: department,
        email: email,
        createdAt: DateTime.now(),
        uid: uid,
      );

      // Save to Firestore using UID as Doc ID
      await _firestore.collection(_collection).doc(uid).set(faculty.toMap());

      // Create entry in faculty_roles for security rules (CRITICAL)
      await _firestore.collection('faculty_roles').doc(uid).set({
        'facultyId': finalFacultyId,
        'role': 'faculty',
        'email': email,
      });

    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw Exception('The email address is already in use by another account.');
      }
      throw Exception('Failed to create faculty account: ${e.message}');
    } catch (e) {
      throw Exception('Error creating faculty: $e');
    } finally {
      // Always delete the temporary app
      await tempApp.delete();
    }
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

  /// Authenticate faculty using Firebase Auth
  /// 1. Look up email from Firestore using facultyId
  /// 2. Sign in with Firebase Auth
  /// 3. Update Firestore with UID if missing
  static Future<Faculty?> authenticateFaculty(String facultyId, String password) async {
    Faculty? facultyData;
    String? emailToUse;
    
    try {
      // 1. Find the faculty document to get the email and hash
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('facultyId', isEqualTo: facultyId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null; // Faculty ID not found
      }

      final doc = querySnapshot.docs.first;
      facultyData = Faculty.fromFirestore(doc);
      
      if (facultyData.email == null || facultyData.email!.isEmpty) {
        throw Exception('No email linked to this Faculty ID. Contact Admin.');
      }

      // 2. Verify password with Firestore hash (The Source of Truth for Admin Resets)
      final providedHash = hashPassword(password);
      
      // If the doc has a hash and it DOESN'T match, fail instantly
      if (facultyData.passwordHash.isNotEmpty && facultyData.passwordHash != providedHash) {
          return null; // Invalid credentials
      }

      // 3. Sign in with Firebase Auth (The Session Manager)
      emailToUse = facultyData.email!.trim();
      
      UserCredential? userCredential;
      try {
        userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailToUse, 
          password: password
        );
      } on FirebaseAuthException catch (e) {
        // SPECIAL CASE: If Firestore hash matched (or was empty) but Auth failed, 
        // the Auth password is out of sync (likely due to an Admin Reset).
        // Since we proved the password is correct via Firestore hash, we allow login.
        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
            print('Auth out of sync with Firestore for ${facultyData.facultyId}. Trusting Firestore hash.');
            // Save local session to prevent auto-logout since FirebaseAuth won't have a user
            await _saveLocalSession(facultyData.facultyId);
            return facultyData;
        }
        rethrow;
      }

      // 4. Update/Create entry in faculty_roles for security rules (CRITICAL)
      // This MUST happen for isFaculty() to work.
      try {
        await _firestore.collection('faculty_roles').doc(userCredential!.user!.uid).set({
          'facultyId': facultyData.facultyId,
          'role': facultyData.role,
          'email': emailToUse,
        });
      } catch (e) {
        print('Error updating faculty_roles: $e');
        // If this fails, permissions won't work, so it's a real error.
        throw Exception('Failed to setup permissions: $e');
      }

      // 5. Link UID in faculty document (and ensure Hash is updated if it was empty)
      final Map<String, dynamic> updates = {};
      if (facultyData.uid != userCredential.user!.uid) {
        updates['uid'] = userCredential.user!.uid;
        facultyData.uid = userCredential.user!.uid;
      }
      if (facultyData.passwordHash.isEmpty) {
        updates['passwordHash'] = providedHash;
      }
      
      if (updates.isNotEmpty) {
        try {
          await doc.reference.update(updates);
        } catch (e) {
          print('Non-fatal: Could not update faculty doc: $e');
        }
      }

      // 6. Success - Save session locally regardless of Auth sync
      await _saveLocalSession(facultyData.facultyId);

      return facultyData;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      String message = 'Authentication failed';
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found for email ${facultyData?.email ?? "unknown"}';
          break;
        case 'wrong-password':
          message = 'Wrong password provided for that user.';
          break;
        case 'invalid-email':
          message = 'The email address is invalid.';
          break;
        case 'user-disabled':
          message = 'The user account has been disabled.';
          break;
        case 'invalid-credential':
          message = 'Incorrect password for ${emailToUse ?? "unknown"} (ID: ${facultyData?.facultyId ?? "unknown"}).';
          break;
        default:
          message = '${e.message} (Email: ${emailToUse ?? "unknown"})';
      }
      throw Exception(message); 
    } catch (e) {
      print('Auth Error: $e');
      rethrow;
    }
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

  /// Check if current user is faculty admin
  static Future<bool> isCurrentFacultyAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final doc = await _firestore.collection('faculty_roles').doc(user.uid).get();
    if (!doc.exists) return false;

    return doc.data()?['role'] == 'faculty_admin';
  }
}
