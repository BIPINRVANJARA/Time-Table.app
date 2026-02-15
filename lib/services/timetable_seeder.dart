
import 'package:flutter/material.dart';
import '../models/subject.dart';
import 'database_service.dart';

class TimetableSeeder {
  static const String branch = 'Computer Engineering'; // Change if needed
  static const String semester = 'Semester 2';
  static const String division = 'A';

  static Future<void> seedData() async {
    final List<Map<String, dynamic>> rawData = [
      // Monday
      {
        "day": 1, // Monday
        "time": "09:30-11:30",
        "subject": "Phy Practical",
        "type": "lab",
        "batch": null, // Common
        "faculty": "",
        "room": ""
      },
      {
        "day": 1,
        "time": "11:30-12:30",
        "subject": "ENR",
        "type": "lecture",
        "faculty": "PDJ",
        "batch": null
      },
      {
        "day": 1,
        "time": "12:30-13:30", // 12:30-01:30 PM
        "subject": "FSD",
        "type": "lecture",
        "faculty": "VPP",
        "batch": null
      },
      {
        "day": 1,
        "time": "14:00-15:00", // 02:00-03:00 PM
        "subject": "PHY",
        "type": "lecture",
        "faculty": "ANP",
        "batch": null
      },
      {
        "day": 1,
        "time": "15:00-17:00", // 03:00-05:00 PM
        "subject": "CPD Lab",
        "type": "lab",
        "batch": "A1",
        "room": "305",
        "faculty": ""
      },
      {
        "day": 1,
        "time": "15:00-17:00",
        "subject": "Python Lab",
        "type": "lab",
        "batch": "A2",
        "room": "306A",
        "faculty": ""
      },

      // Tuesday
      {
        "day": 2, // Tuesday
        "time": "10:30-11:30",
        "subject": "FSD",
        "type": "lecture",
        "faculty": "VPP",
        "batch": null
      },
      {
        "day": 2,
        "time": "11:30-12:30",
        "subject": "Advanced Python",
        "type": "lecture",
        "faculty": "RAM",
        "batch": null
      },
      {
        "day": 2,
        "time": "12:30-13:30",
        "subject": "Maths",
        "type": "lecture",
        "faculty": "JCD",
        "batch": null
      },
      {
        "day": 2,
        "time": "14:00-15:00",
        "subject": "IC",
        "type": "lecture",
        "faculty": "BSP",
        "batch": null
      },
      {
        "day": 2,
        "time": "15:00-17:00",
        "subject": "Advanced Python Lab",
        "type": "lab",
        "batch": "A3",
        "room": "306A",
        "faculty": ""
      },

      // Wednesday
      {
        "day": 3, // Wednesday
        "time": "10:30-11:30",
        "subject": "ENR",
        "type": "lecture",
        "faculty": "PDJ",
        "batch": null
      },
      {
        "day": 3,
        "time": "11:30-12:30",
        "subject": "PHY",
        "type": "lecture",
        "faculty": "ANP",
        "batch": null
      },
      {
        "day": 3,
        "time": "12:30-13:30",
        "subject": "Maths",
        "type": "lecture",
        "faculty": "JCD",
        "batch": null
      },
      {
        "day": 3,
        "time": "14:00-15:00",
        "subject": "Advanced Python",
        "type": "lecture",
        "faculty": "RAM",
        "batch": null
      },
      {
        "day": 3,
        "time": "15:00-17:00",
        "subject": "CPD Lab",
        "type": "lab",
        "batch": "A2",
        "room": "305",
        "faculty": ""
      },

      // Thursday
      {
        "day": 4, // Thursday
        "time": "10:30-11:30",
        "subject": "Advanced Python",
        "type": "lecture",
        "faculty": "RAM",
        "batch": null
      },
      {
        "day": 4,
        "time": "11:30-12:30",
        "subject": "Maths",
        "type": "lecture",
        "faculty": "JCD",
        "batch": null
      },
      {
        "day": 4,
        "time": "12:30-13:30",
        "subject": "CPD",
        "type": "lecture",
        "faculty": "RSJ",
        "batch": null
      },
      {
        "day": 4,
        "time": "14:00-15:00",
        "subject": "FSD",
        "type": "lecture",
        "faculty": "VPP",
        "batch": null
      },
      {
        "day": 4,
        "time": "15:00-17:00",
        "subject": "Advanced Python Lab",
        "type": "lab",
        "batch": "A1",
        "room": "306A",
        "faculty": ""
      },
      {
        "day": 4,
        "time": "15:00-17:00",
        "subject": "CPD Lab",
        "type": "lab",
        "batch": "A3",
        "room": "305",
        "faculty": ""
      },

      // Friday
      {
        "day": 5, // Friday
        "time": "10:30-11:30",
        "subject": "IC",
        "type": "lecture",
        "faculty": "BSP",
        "batch": null
      },
      {
        "day": 5,
        "time": "11:30-12:30",
        "subject": "CPD",
        "type": "lecture",
        "faculty": "NPP",
        "batch": null
      },
      {
        "day": 5,
        "time": "12:30-13:30",
        "subject": "PHY",
        "type": "lecture",
        "faculty": "ANP",
        "batch": null
      },
      {
        "day": 5,
        "time": "14:00-15:00",
        "subject": "Maths Tutorial",
        "type": "tutorial",
        "batch": null, // Common
        "faculty": ""
      }
    ];

    print('Seeding ${rawData.length} subjects...');

    for (final data in rawData) {
      final timeParts = (data['time'] as String).split('-');
      final startParts = timeParts[0].split(':');
      final endParts = timeParts[1].split(':');

      final startHour = int.parse(startParts[0]);
      final startMinute = int.parse(startParts[1]);
      final endHour = int.parse(endParts[0]);
      final endMinute = int.parse(endParts[1]);

      final subject = Subject(
        id: '', // Will be generated
        subjectName: data['subject'],
        facultyName: data['faculty'] ?? '',
        type: data['type'],
        dayOfWeek: data['day'],
        startHour: startHour,
        startMinute: startMinute,
        endHour: endHour,
        endMinute: endMinute,
        batch: data['batch'],
        roomNumber: data['room'],
        reminderEnabled: true, // Default enabled
        reminderMinutesBefore: 5,
      );

      await DatabaseService.addSubject(branch, semester, division, subject);
      print('Added: ${subject.subjectName} on Day ${subject.dayOfWeek}');
    }
  }
}
