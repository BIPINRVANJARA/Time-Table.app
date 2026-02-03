import 'package:hive/hive.dart';

part 'subject.g.dart';

@HiveType(typeId: 0)
class Subject extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String subjectName;

  @HiveField(2)
  int dayOfWeek; // 1=Monday, 2=Tuesday, ..., 7=Sunday

  @HiveField(3)
  int startHour;

  @HiveField(4)
  int startMinute;

  @HiveField(5)
  int endHour;

  @HiveField(6)
  int endMinute;

  @HiveField(7)
  int colorValue; // Color stored as int

  @HiveField(8)
  bool reminderEnabled;

  @HiveField(9)
  int reminderMinutesBefore; // e.g., 10 minutes before class

  Subject({
    required this.id,
    required this.subjectName,
    required this.dayOfWeek,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    required this.colorValue,
    this.reminderEnabled = false,
    this.reminderMinutesBefore = 10,
  });

  // Helper method to get start time as DateTime (for today)
  DateTime get startTime {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, startHour, startMinute);
  }

  // Helper method to get end time as DateTime (for today)
  DateTime get endTime {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, endHour, endMinute);
  }

  // Helper method to get formatted time string
  String get timeRange {
    String formatTime(int hour, int minute) {
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
    }

    return '${formatTime(startHour, startMinute)} - ${formatTime(endHour, endMinute)}';
  }

  // Get day name
  String get dayName {
    const days = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[dayOfWeek];
  }

  // Get short day name
  String get shortDayName {
    const days = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[dayOfWeek];
  }
}
