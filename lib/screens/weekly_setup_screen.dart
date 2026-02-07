import 'package:flutter/material.dart';

class WeeklySetupScreen extends StatelessWidget {
  const WeeklySetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Schedule Setup')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Icon(Icons.lock_rounded, size: 64, color: Colors.grey),
             SizedBox(height: 16),
             Text(
              'Admin Access Only',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
             SizedBox(height: 8),
             Text(
              'Timetable management is now centralized.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
