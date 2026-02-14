import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// Centralized authentication service for security-critical operations
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Get current user
  static User? get currentUser => _auth.currentUser;

  /// Check if current user's email is verified
  static bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  /// Check if current user has admin role
  static Future<bool> isAdmin() async {
    final uid = currentUser?.uid;
    if (uid == null) return false;

    try {
      final userDoc = await _db.collection('users').doc(uid).get();
      if (!userDoc.exists) return false;

      final userData = userDoc.data();
      return userData?['role'] == 'admin';
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  /// Require admin role - throws exception if not admin
  static Future<void> requireAdmin() async {
    if (!await isAdmin()) {
      throw Exception('Admin access required');
    }
  }

  /// Reload current user to get latest email verification status
  static Future<void> reloadUser() async {
    await currentUser?.reload();
  }

  /// Send email verification to current user
  static Future<void> sendEmailVerification() async {
    final user = currentUser;
    if (user == null) throw Exception('No user logged in');
    if (user.emailVerified) throw Exception('Email already verified');

    await user.sendEmailVerification();
  }

  /// Re-authenticate user with password (for sensitive operations)
  static Future<bool> reauthenticateWithPassword(String password) async {
    final user = currentUser;
    if (user == null || user.email == null) return false;

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
      return true;
    } catch (e) {
      print('Re-authentication failed: $e');
      return false;
    }
  }

  /// Sign out current user
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Validate password strength
  /// Returns null if valid, error message if invalid
  static String? validatePasswordStrength(String password) {
    if (password.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character';
    }
    return null;
  }

  /// Get password strength score (0-4)
  /// 0 = Very Weak, 1 = Weak, 2 = Fair, 3 = Good, 4 = Strong
  static int getPasswordStrength(String password) {
    int score = 0;
    
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (password.contains(RegExp(r'[A-Z]')) && password.contains(RegExp(r'[a-z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;

    return score > 4 ? 4 : score;
  }

  /// Get password strength label
  static String getPasswordStrengthLabel(int strength) {
    switch (strength) {
      case 0:
        return 'Very Weak';
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Strong';
      default:
        return 'Unknown';
    }
  }
}
