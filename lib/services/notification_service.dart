import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/subject.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // Initialize the notification service
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone database
    tz.initializeTimeZones();
    
    // Set local timezone to India (Asia/Kolkata)
    // This is CRITICAL for notifications to work correctly
    final location = tz.getLocation('Asia/Kolkata');
    tz.setLocalLocation(location);

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
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
    await _requestPermissions();

    _initialized = true;
  }

  // Request notification permissions
  Future<void> _requestPermissions() async {
    final androidPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      await androidPlugin.requestExactAlarmsPermission();
    }

    final iosPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - can navigate to specific screen
    print('Notification tapped: ${response.payload}');
  }

  // Schedule a weekly repeating notification for a subject
  Future<void> scheduleSubjectNotification(Subject subject) async {
    if (!subject.reminderEnabled) return;

    final notificationId = subject.id.hashCode;

    // Calculate notification time (subject start time - reminder minutes)
    final notificationTime = _getNotificationTime(
      subject.dayOfWeek,
      subject.startHour,
      subject.startMinute,
      subject.reminderMinutesBefore,
    );

    const androidDetails = AndroidNotificationDetails(
      'class_reminders',
      'Class Reminders',
      channelDescription: 'Notifications for upcoming classes',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails();

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Format the start time for notification
    String formatTime(int hour, int minute) {
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
    }

    await _notifications.zonedSchedule(
      notificationId,
      'Next Lecture: ${subject.subjectName}',
      'Starts at ${formatTime(subject.startHour, subject.startMinute)} (in ${subject.reminderMinutesBefore} minutes)',
      notificationTime,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: subject.id,
    );
  }

  // Get the next notification time for a subject
  tz.TZDateTime _getNotificationTime(
    int dayOfWeek,
    int startHour,
    int startMinute,
    int minutesBefore,
  ) {
    final now = tz.TZDateTime.now(tz.local);
    
    // Calculate the notification time
    int notificationHour = startHour;
    int notificationMinute = startMinute - minutesBefore;

    // Handle minute overflow
    if (notificationMinute < 0) {
      notificationMinute += 60;
      notificationHour -= 1;
    }

    // Handle hour overflow
    if (notificationHour < 0) {
      notificationHour += 24;
    }

    // Find the next occurrence of this day and time
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      notificationHour,
      notificationMinute,
    );

    // Adjust to the correct day of week
    while (scheduledDate.weekday != dayOfWeek) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // If the time has passed today, schedule for next week
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }

    return scheduledDate;
  }

  // Cancel a notification for a subject
  Future<void> cancelSubjectNotification(String subjectId) async {
    final notificationId = subjectId.hashCode;
    await _notifications.cancel(notificationId);
  }

  // Get all pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      final pending = await _notifications.pendingNotificationRequests();
      return pending;
    } catch (e) {
      print('Error getting pending notifications: $e');
      return [];
    }
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
    } catch (e) {
      print('Error canceling notifications: $e');
    }
  }

  // Reschedule all subject notifications
  Future<void> rescheduleAllNotifications() async {
    try {
      // Cancel all existing notifications
      await cancelAllNotifications();

      // Get all subjects with reminders enabled
      final subjects = DatabaseService.getAllSubjects()
          .where((subject) => subject.reminderEnabled)
          .toList();

      // Schedule notification for each subject
      for (final subject in subjects) {
        await scheduleSubjectNotification(subject);
      }
    } catch (e) {
      print('Error rescheduling notifications: $e');
    }
  }

  // Reschedule notification (useful when subject is updated)
  Future<void> rescheduleSubjectNotification(Subject subject) async {
    await cancelSubjectNotification(subject.id);
    await scheduleSubjectNotification(subject);
  }

  // Test notification (fires immediately)
  Future<void> testNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      channelDescription: 'Test notifications for debugging',
      importance: Importance.high,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      999999,
      'Test Notification',
      'If you see this, notifications are working! 🎉',
      notificationDetails,
    );
  }
}
