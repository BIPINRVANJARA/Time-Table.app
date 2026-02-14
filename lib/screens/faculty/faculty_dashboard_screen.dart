import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/subject.dart';
import '../../services/database_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/date_selector.dart';
import '../../widgets/subject_card.dart';
import '../login_screen.dart';

class FacultyDashboardScreen extends StatefulWidget {
  final String facultyId;
  final String facultyName;

  const FacultyDashboardScreen({
    super.key,
    required this.facultyId,
    required this.facultyName,
  });

  @override
  State<FacultyDashboardScreen> createState() => _FacultyDashboardScreenState();
}

class _FacultyDashboardScreenState extends State<FacultyDashboardScreen> {
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
              "Today's Lectures",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            Text(
              'Welcome, ${widget.facultyName}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
                color: Colors.black54,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black54),
            tooltip: 'Logout',
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
          ),
        ],
      ),
      body: Column(
        children: [
          // Date selector
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

          // Lectures list
          Expanded(
            child: StreamBuilder<List<Subject>>(
              stream: _streamFacultyLectures(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final allLectures = snapshot.data ?? [];
                
                // Schedule notifications for faculty lectures
                // We pass null for batch as faculty teaches multiple batches, but set isFaculty to true
                NotificationService().rescheduleAllNotifications(
                  allLectures,
                  null,
                  isFaculty: true,
                );
                
                // Filter by selected day
                final lectures = allLectures
                    .where((s) => s.dayOfWeek == dayOfWeek)
                    .toList();
                
                // Sort by time
                lectures.sort((a, b) => a.startInMinutes.compareTo(b.startInMinutes));

                if (lectures.isEmpty) {
                  return _buildEmptyState(dayOfWeek);
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  physics: const BouncingScrollPhysics(),
                  itemCount: lectures.length,
                  itemBuilder: (context, index) {
                    final lecture = lectures[index];
                    return SubjectCard(
                      key: ValueKey(lecture.id),
                      subject: lecture,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Stream lectures assigned to this faculty
  Stream<List<Subject>> _streamFacultyLectures() {
    // Get all timetables and filter by facultyId
    // This is a simplified approach - in production, you'd want to optimize this query
    return DatabaseService.streamAllTimetables()
        .map((subjects) => subjects
            .where((s) => s.facultyId == widget.facultyId)
            .toList());
  }

  Widget _buildEmptyState(int dayOfWeek) {
    final dayName = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][dayOfWeek];
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.event_available,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            dayOfWeek == 7 ? 'It\'s Sunday! 🎉' : 'No lectures today! 🎉',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No lectures scheduled for $dayName',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
