import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AttendancePhotoService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final ImagePicker _picker = ImagePicker();

  /// Group ID for Firestore path
  static String _groupId(String semester, String division, String batch) {
    return '${semester}_${division}_$batch'.replaceAll(' ', '');
  }

  /// Capture photo and upload to Firebase Storage + save metadata to Firestore
  static Future<void> captureAndUploadAttendancePhoto({
    required BuildContext context,
    required String semester,
    required String division,
    required String batch,
    required String subjectId,
    required String subjectName,
    required String facultyId,
  }) async {
    try {
      // 1. Open camera to capture photo
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (photo == null) {
        // User cancelled camera
        return;
      }

      if (!context.mounted) return;

      // Show uploading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Uploading attendance photo...'),
                ],
              ),
            ),
          ),
        ),
      );

      // 2. Upload to Firebase Storage
      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final timeStr = DateFormat('HHmmss').format(DateTime.now());
      final groupId = _groupId(semester, division, batch);
      final storagePath =
          'attendance_photos/$groupId/$subjectId/${dateStr}_$timeStr.jpg';

      final ref = _storage.ref().child(storagePath);
      final uploadTask = await ref.putFile(
        File(photo.path),
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // 3. Save metadata to Firestore
      await _db
          .collection('attendance')
          .doc(groupId)
          .collection('subjects')
          .doc(subjectId)
          .collection('photos')
          .add({
        'date': dateStr,
        'time': timeStr,
        'photoUrl': downloadUrl,
        'storagePath': storagePath,
        'subjectId': subjectId,
        'subjectName': subjectName,
        'semester': semester,
        'division': division,
        'batch': batch,
        'facultyId': facultyId,
        'uploadedAt': FieldValue.serverTimestamp(),
      });

      if (!context.mounted) return;
      Navigator.pop(context); // Pop loading dialog

      // 4. Show success
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Photo Uploaded!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$subjectName',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Date: ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(photo.path),
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'The attendance photo has been saved successfully.',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (context.mounted) {
        // Pop loading dialog if it's showing
        Navigator.of(context, rootNavigator: true).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
