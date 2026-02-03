import 'package:flutter/material.dart';
import '../models/subject.dart';
import '../services/database_service.dart';

class TimeDebugScreen extends StatelessWidget {
  const TimeDebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final allSubjects = DatabaseService.getAllSubjects();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Time Sorting Debug'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'All Subjects (Sorted by Time)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...allSubjects.map((subject) {
            return Card(
              child: ListTile(
                title: Text(subject.subjectName),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Day: ${subject.dayName}'),
                    Text('Time: ${subject.timeRange}'),
                    Text(
                      'Minutes since midnight: ${subject.startInMinutes}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    Text('Hour: ${subject.startHour}, Minute: ${subject.startMinute}'),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'Today\'s Subjects (Should be in order)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...DatabaseService.getTodaySubjects().map((subject) {
            return Card(
              color: Colors.green.shade50,
              child: ListTile(
                title: Text(subject.subjectName),
                subtitle: Text('${subject.timeRange} (${subject.startInMinutes} min)'),
              ),
            );
          }),
        ],
      ),
    );
  }
}
