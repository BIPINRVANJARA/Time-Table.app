import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import 'time_debug_screen.dart';

class NotificationDebugScreen extends StatefulWidget {
  const NotificationDebugScreen({super.key});

  @override
  State<NotificationDebugScreen> createState() => _NotificationDebugScreenState();
}

class _NotificationDebugScreenState extends State<NotificationDebugScreen> {
  List<String> _logs = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Debug'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ElevatedButton(
            onPressed: _testImmediateNotification,
            child: const Text('Test Immediate Notification'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _checkPendingNotifications,
            child: const Text('Check Pending Notifications'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _rescheduleAllNotifications,
            child: const Text('Reschedule All Notifications'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const TimeDebugScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('View Time Sorting Debug'),
          ),
          const SizedBox(height: 24),
          const Text(
            'Debug Logs:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ..._logs.map((log) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(log, style: const TextStyle(fontSize: 12)),
              )),
        ],
      ),
    );
  }

  Future<void> _testImmediateNotification() async {
    setState(() {
      _logs.add('${DateTime.now()}: Testing immediate notification...');
    });

    try {
      await NotificationService().testNotification();
      setState(() {
        _logs.add('${DateTime.now()}: ✅ Immediate notification sent!');
      });
    } catch (e) {
      setState(() {
        _logs.add('${DateTime.now()}: ❌ Error: $e');
      });
    }
  }

  Future<void> _checkPendingNotifications() async {
    setState(() {
      _logs.add('${DateTime.now()}: Checking pending notifications...');
    });

    try {
      final pending = await NotificationService().getPendingNotifications();
      setState(() {
        _logs.add('${DateTime.now()}: Found ${pending.length} pending notifications');
        for (var notification in pending) {
          _logs.add('  - ID: ${notification.id}, Title: ${notification.title}');
        }
      });
    } catch (e) {
      setState(() {
        _logs.add('${DateTime.now()}: ❌ Error: $e');
      });
    }
  }

  Future<void> _rescheduleAllNotifications() async {
    setState(() {
      _logs.add('${DateTime.now()}: Rescheduling all notifications...');
    });

    try {
      final subjects = DatabaseService.getAllSubjects();
      for (var subject in subjects) {
        if (subject.reminderEnabled) {
          await NotificationService().rescheduleSubjectNotification(subject);
          setState(() {
            _logs.add('  - Scheduled: ${subject.subjectName}');
          });
        }
      }
      setState(() {
        _logs.add('${DateTime.now()}: ✅ All notifications rescheduled!');
      });
    } catch (e) {
      setState(() {
        _logs.add('${DateTime.now()}: ❌ Error: $e');
      });
    }
  }
}
