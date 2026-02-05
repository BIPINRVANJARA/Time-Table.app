import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/subject.dart';
import '../services/database_service.dart';
import '../utils/theme.dart';
import '../widgets/subject_card.dart';
import '../widgets/date_selector.dart';
import 'weekly_setup_screen.dart';
import 'add_edit_subject_screen.dart';
import 'notification_debug_screen.dart';

class TodayScheduleScreen extends StatefulWidget {
  const TodayScheduleScreen({super.key});

  @override
  State<TodayScheduleScreen> createState() => _TodayScheduleScreenState();
}

class _TodayScheduleScreenState extends State<TodayScheduleScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final dayOfWeek = _selectedDate.weekday;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Today's Schedule,",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            Text(
              DateFormat('MMMM, d').format(_selectedDate),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            tooltip: 'Debug Notifications',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const NotificationDebugScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit_calendar),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const WeeklySetupScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Horizontal date selector
          Container(
            color: Colors.white,
            child: DateSelector(
              selectedDate: _selectedDate,
              onDateSelected: (date) {
                setState(() {
                  _selectedDate = date;
                });
              },
            ),
          ),

          // Subject list
          Expanded(
            child: StreamBuilder(
              stream: DatabaseService.subjectsBox.watch(),
              builder: (context, snapshot) {
                final subjects = DatabaseService.getSubjectsByDay(dayOfWeek);

                if (subjects.isEmpty) {
                  return _buildEmptyState(dayOfWeek);
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  physics: const BouncingScrollPhysics(),
                  itemCount: subjects.length,
                  itemBuilder: (context, index) {
                    final subject = subjects[index];
                    return RepaintBoundary(
                      child: SubjectCard(
                        key: ValueKey(subject.id),
                        subject: subject,
                        onTap: () => _editSubject(subject),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AddEditSubjectScreen(
                dayOfWeek: _selectedDate.weekday,
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }


  Widget _buildEmptyState(int dayOfWeek) {
    final dayName = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][dayOfWeek];
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available,
            size: 80,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            dayOfWeek == 7 ? 'It\'s Sunday! 🎉' : 'No classes today! 🎉',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No classes scheduled for $dayName',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const WeeklySetupScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Classes'),
          ),
        ],
      ),
    );
  }

  void _editSubject(Subject subject) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditSubjectScreen(subject: subject),
      ),
    );
  }
}
