import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  final db = FirebaseFirestore.instance;
  final snapshot = await db.collection('students').get();
  
  print("=== FOUND \${snapshot.docs.length} STUDENT GROUPS ===");
  for (var doc in snapshot.docs) {
    print("Group ID: \${doc.id}");
    final entries = await doc.reference.collection('entries').get();
    print("  -> Has \${entries.docs.length} entries.");
  }
}
