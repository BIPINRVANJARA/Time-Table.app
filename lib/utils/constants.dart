class AppConstants {
  // App info
  static const String appName = 'Timecloud';
  static const String appVersion = '1.0.0';

  // Days of week
  static const List<String> daysOfWeek = [
    '',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const List<String> shortDaysOfWeek = [
    '',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  // Reminder options (in minutes)
  static const List<int> reminderOptions = [5, 10, 15, 30];

  // Default reminder time
  static const int defaultReminderMinutes = 10;

  // Preferences keys
  static const String prefFirstLaunch = 'first_launch';
  static const String prefDefaultReminderTime = 'default_reminder_time';
  static const String prefNotificationsEnabled = 'notifications_enabled';
  static const String prefDarkMode = 'dark_mode';
}
