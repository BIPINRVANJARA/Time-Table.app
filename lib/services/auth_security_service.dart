import 'package:shared_preferences/shared_preferences.dart';

/// Service to handle authentication security features like rate limiting
/// and password validation
class AuthSecurityService {
  // Rate limiting constants
  static const int maxFailedAttempts = 5;
  static const int lockoutDurationMinutes = 15;
  static const String _failedAttemptsKey = 'failed_login_attempts';
  static const String _lockoutUntilKey = 'lockout_until';
  static const String _lastAttemptEmailKey = 'last_attempt_email';

  // Password validation constants
  static const int minPasswordLength = 8;
  static final RegExp uppercaseRegex = RegExp(r'[A-Z]');
  static final RegExp lowercaseRegex = RegExp(r'[a-z]');
  static final RegExp digitRegex = RegExp(r'[0-9]');
  static final RegExp specialCharRegex = RegExp(r'[!@#$%^&*(),.?":{}|<>]');

  /// Check if account is currently locked out
  static Future<bool> isLockedOut() async {
    final prefs = await SharedPreferences.getInstance();
    final lockoutUntil = prefs.getInt(_lockoutUntilKey);
    
    if (lockoutUntil == null) return false;
    
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now < lockoutUntil) {
      return true; // Still locked out
    } else {
      // Lockout expired, clear it
      await _clearLockout();
      return false;
    }
  }

  /// Get remaining lockout time in minutes
  static Future<int> getRemainingLockoutMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    final lockoutUntil = prefs.getInt(_lockoutUntilKey);
    
    if (lockoutUntil == null) return 0;
    
    final now = DateTime.now().millisecondsSinceEpoch;
    final remaining = lockoutUntil - now;
    
    if (remaining <= 0) return 0;
    
    return (remaining / 60000).ceil(); // Convert to minutes
  }

  /// Record a failed login attempt
  static Future<void> recordFailedAttempt(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final lastEmail = prefs.getString(_lastAttemptEmailKey);
    
    // Reset counter if different email
    if (lastEmail != email) {
      await prefs.setInt(_failedAttemptsKey, 1);
      await prefs.setString(_lastAttemptEmailKey, email);
      return;
    }
    
    // Increment failed attempts
    final attempts = (prefs.getInt(_failedAttemptsKey) ?? 0) + 1;
    await prefs.setInt(_failedAttemptsKey, attempts);
    
    // Lock account if max attempts reached
    if (attempts >= maxFailedAttempts) {
      final lockoutUntil = DateTime.now()
          .add(Duration(minutes: lockoutDurationMinutes))
          .millisecondsSinceEpoch;
      await prefs.setInt(_lockoutUntilKey, lockoutUntil);
    }
  }

  /// Get current failed attempt count
  static Future<int> getFailedAttemptCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_failedAttemptsKey) ?? 0;
  }

  /// Clear failed attempts (call on successful login)
  static Future<void> clearFailedAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_failedAttemptsKey);
    await prefs.remove(_lastAttemptEmailKey);
    await prefs.remove(_lockoutUntilKey);
  }

  /// Clear lockout
  static Future<void> _clearLockout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_failedAttemptsKey);
    await prefs.remove(_lockoutUntilKey);
    await prefs.remove(_lastAttemptEmailKey);
  }

  /// Validate password strength
  /// Returns null if valid, error message if invalid
  static String? validatePasswordStrength(String password) {
    if (password.length < minPasswordLength) {
      return 'Password must be at least $minPasswordLength characters';
    }
    
    if (!uppercaseRegex.hasMatch(password)) {
      return 'Password must contain at least one uppercase letter';
    }
    
    if (!lowercaseRegex.hasMatch(password)) {
      return 'Password must contain at least one lowercase letter';
    }
    
    if (!digitRegex.hasMatch(password)) {
      return 'Password must contain at least one number';
    }
    
    if (!specialCharRegex.hasMatch(password)) {
      return 'Password must contain at least one special character (!@#\$%^&*...)';
    }
    
    return null; // Valid password
  }

  /// Calculate password strength (0-4)
  /// 0 = Very Weak, 1 = Weak, 2 = Fair, 3 = Good, 4 = Strong
  static int calculatePasswordStrength(String password) {
    int strength = 0;
    
    if (password.length >= minPasswordLength) strength++;
    if (uppercaseRegex.hasMatch(password)) strength++;
    if (digitRegex.hasMatch(password)) strength++;
    if (specialCharRegex.hasMatch(password)) strength++;
    
    return strength;
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

  /// Get password strength color
  static int getPasswordStrengthColor(int strength) {
    switch (strength) {
      case 0:
      case 1:
        return 0xFFE53935; // Red
      case 2:
        return 0xFFFB8C00; // Orange
      case 3:
        return 0xFFFDD835; // Yellow
      case 4:
        return 0xFF43A047; // Green
      default:
        return 0xFF9E9E9E; // Grey
    }
  }
}
