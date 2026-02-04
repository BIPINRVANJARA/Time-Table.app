import 'package:flutter/material.dart';
import '../models/subject.dart';
import '../services/database_service.dart';
import '../utils/theme.dart';
import '../widgets/subject_card.dart';
import 'add_edit_subject_screen.dart';
import 'today_schedule_screen.dart';

class WeeklySetupScreen extends StatefulWidget {
  const WeeklySetupScreen({super.key});

  @override
  State<WeeklySetupScreen> createState() => _WeeklySetupScreenState();
}

class _WeeklySetupScreenState extends State<WeeklySetupScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Weekly Timetable',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              // Navigate to Today's Schedule
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const TodayScheduleScreen(),
                ),
              );
            },
            icon: const Icon(Icons.check),
            label: const Text('Done'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.blue,
          labelColor: AppColors.blue,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Monday'),
            Tab(text: 'Tuesday'),
            Tab(text: 'Wednesday'),
            Tab(text: 'Thursday'),
            Tab(text: 'Friday'),
            Tab(text: 'Saturday'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDayView(1), // Monday
          _buildDayView(2), // Tuesday
          _buildDayView(3), // Wednesday
          _buildDayView(4), // Thursday
          _buildDayView(5), // Friday
          _buildDayView(6), // Saturday
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addSubject(),
        icon: const Icon(Icons.add),
        label: const Text('Add Subject'),
      ),
    );
  }

  Widget _buildDayView(int dayOfWeek) {
    return StreamBuilder(
      stream: DatabaseService.subjectsBox.watch(),
      builder: (context, snapshot) {
        final subjects = DatabaseService.getSubjectsByDay(dayOfWeek);

        if (subjects.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_busy,
                  size: 80,
                  color: AppColors.textSecondary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No classes scheduled',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the + button to add a subject',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          );
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
                onDelete: () => _deleteSubject(subject),
              ),
            );
          },
        );
      },
    );
  }

  void _addSubject() async {
    final currentDay = _tabController.index + 1; // 1-based day index
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditSubjectScreen(dayOfWeek: currentDay),
      ),
    );

    if (result == true && mounted) {
      setState(() {});
    }
  }

  void _editSubject(Subject subject) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditSubjectScreen(subject: subject),
      ),
    );

    if (result == true && mounted) {
      setState(() {});
    }
  }

  void _deleteSubject(Subject subject) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subject'),
        content: Text('Are you sure you want to delete ${subject.subjectName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseService.deleteSubject(subject.id);
      if (mounted) {
        setState(() {});
      }
    }
  }
}
