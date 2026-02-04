import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/subject.dart';
import '../services/database_service.dart';
import '../utils/theme.dart';
import '../widgets/subject_card.dart';
import 'weekly_setup_screen.dart';
import 'add_edit_subject_screen.dart';
import 'notification_debug_screen.dart';

class TodayScheduleScreen extends StatefulWidget {
  const TodayScheduleScreen({super.key});

  @override
  State<TodayScheduleScreen> createState() => _TodayScheduleScreenState();
}

class _TodayScheduleScreenState extends State<TodayScheduleScreen> {
  int _selectedDayOffset = 0; // 0 = today, -1 = yesterday, +1 = tomorrow

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final selectedDate = today.add(Duration(days: _selectedDayOffset));
    final dayOfWeek = selectedDate.weekday;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Today\'s Schedule',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              DateFormat('EEEE, MMMM d').format(selectedDate),
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.normal,
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
          // Date selector
          _buildDateSelector(today),
          const Divider(height: 1),

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
                dayOfWeek: selectedDate.weekday,
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDateSelector(DateTime today) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemBuilder: (context, index) {
          final offset = index - 3; // -3 to +3 days
          final date = today.add(Duration(days: offset));
          final isSelected = offset == _selectedDayOffset;
          final isToday = offset == 0;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDayOffset = offset;
              });
            },
            child: Container(
              width: 60,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.blue : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isToday
                      ? AppColors.orange
                      : (isSelected ? AppColors.blue : AppColors.divider),
                  width: isToday ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE').format(date),
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
