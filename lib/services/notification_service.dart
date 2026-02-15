import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  /// Initialize the notification service
  Future<void> initialize() async {
    // Initialize timezone data
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions for Android 13+
    await requestPermissions();
  }

  /// Request notification permissions
  Future<void> requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      // Request notification permissions (Android 13+)
      await androidImplementation.requestNotificationsPermission();
      
      // Request exact alarm permissions (Android 12+)
      // This might open system settings if not granted
      await androidImplementation.requestExactAlarmsPermission();
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - navigate to relevant screen
    // This can be implemented based on your app's navigation structure
  }

  /// Schedule a notification for a subject
  Future<void> scheduleSubjectNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'timetable_channel',
          'Timetable Notifications',
          channelDescription: 'Notifications for upcoming classes',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Reschedule all notifications for subjects
  Future<void> rescheduleAllNotifications(
    List<dynamic> subjects,
    String? batch, {
    bool isFaculty = false,
  }) async {
    try {
      // Cancel all existing notifications
      await _notifications.cancelAll();

      // Get current date/time
      final now = DateTime.now();

      // Schedule notifications for each subject
      for (int i = 0; i < subjects.length; i++) {
        final subject = subjects[i];

        // Skip if reminder is not enabled
        if (subject.reminderEnabled != true) {
          continue;
        }

        // Filter logic:
        // For Students: Skip if subject is for a specific batch and doesn't match user's batch
        // For Faculty: Show ALL subjects assigned to them (batch check ignored as they teach the batch)
        if (!isFaculty && subject.batch != null && subject.batch.isNotEmpty && subject.batch != batch) {
          continue;
        }

        // Calculate the next occurrence of this subject
        final dayOfWeek = subject.dayOfWeek as int; // 1=Monday, 7=Sunday
        final startHour = subject.startHour as int;
        final startMinute = subject.startMinute as int;
        final reminderMinutesBefore = subject.reminderMinutesBefore as int? ?? 5;

        // Find the next date when this subject occurs
        DateTime nextOccurrence = _getNextOccurrence(now, dayOfWeek, startHour, startMinute);

        // Subtract reminder time
        final notificationTime = nextOccurrence.subtract(Duration(minutes: reminderMinutesBefore));

        // Only schedule if notification time is in the future
        if (notificationTime.isAfter(now)) {
          String bodyText;
          if (isFaculty) {
             bodyText = 'Class: ${subject.batch ?? "All"} • Room: ${subject.roomNumber ?? "TBA"}';
          } else {
             bodyText = 'Faculty: ${subject.facultyName ?? "TBA"} • ${subject.type ?? "Lecture"}';
          }

          await scheduleSubjectNotification(
            id: i, // Use index as unique ID
            title: '${subject.subjectName} in $reminderMinutesBefore minutes',
            body: bodyText,
            scheduledTime: notificationTime,
          );

          print('DEBUG: Scheduled notification for ${subject.subjectName} at $notificationTime');
        }
      }

      print('DEBUG: Rescheduled ${subjects.length} subject notifications');
    } catch (e) {
      print('ERROR: Failed to reschedule notifications: $e');
    }
  }

  /// Get the next occurrence of a day/time
  DateTime _getNextOccurrence(DateTime now, int targetDayOfWeek, int hour, int minute) {
    // Current day of week (1=Monday, 7=Sunday)
    final currentDayOfWeek = now.weekday;

    // Calculate days until target day
    int daysUntilTarget = targetDayOfWeek - currentDayOfWeek;

    // If target day is today, check if time has passed
    if (daysUntilTarget == 0) {
      final targetTime = DateTime(now.year, now.month, now.day, hour, minute);
      if (targetTime.isAfter(now)) {
        return targetTime; // Today, but later
      } else {
        daysUntilTarget = 7; // Next week
      }
    } else if (daysUntilTarget < 0) {
      daysUntilTarget += 7; // Next week
    }

    // Calculate the target date
    final targetDate = now.add(Duration(days: daysUntilTarget));
    return DateTime(targetDate.year, targetDate.month, targetDate.day, hour, minute);
  }


  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}
