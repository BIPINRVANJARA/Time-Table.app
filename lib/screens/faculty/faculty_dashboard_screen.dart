import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/subject.dart';
import '../../services/database_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/date_selector.dart';
import '../../widgets/subject_card.dart';
import '../login_screen.dart';
import 'personal_subject_dialog.dart';

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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSubjectDialog,
        backgroundColor: const Color(0xFF7BA5E8),
        child: const Icon(Icons.add),
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
                    return Dismissible(
                      key: ValueKey(lecture.id),
                      direction: lecture.isPersonal ? DismissDirection.endToStart : DismissDirection.none,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Subject?'),
                            content: const Text('Are you sure you want to delete this personal subject?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: const Text('Delete', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (direction) {
                        _deletePersonalSubject(lecture.id);
                      },
                      child: SubjectCard(
                        key: ValueKey(lecture.id),
                        subject: lecture,
                        onTap: lecture.isPersonal ? () => _showEditNote(context) : null,
                      ),
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

  void _showAddSubjectDialog() {
    showDialog(
      context: context,
      builder: (context) => PersonalSubjectDialog(
        onAdd: (subject) async {
          await DatabaseService.addPersonalSubject(widget.facultyId, subject);
        },
      ),
    );
  }

  Future<void> _deletePersonalSubject(String subjectId) async {
      await DatabaseService.deletePersonalSubject(widget.facultyId, subjectId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subject deleted')),
      );
  }

  void _showEditNote(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tap and hold to delete personal subjects')),
    );
  }

  /// Stream lectures assigned to this faculty AND personal subjects
  Stream<List<Subject>> _streamFacultyLectures() {
    // 1. Stream official lectures
    final officialStream = DatabaseService.streamAllTimetables()
        .map((subjects) => subjects
            .where((s) => s.facultyId == widget.facultyId)
            .toList());

    // 2. Stream personal subjects
    final personalStream = DatabaseService.streamPersonalSubjects(widget.facultyId);

    // 3. Merge streams using RxDart-style combination (using StreamZip or generic combine)
    // Since Dart core doesn't have combineLatest easily without rxdart, we can use a custom combiner
    // Or just simple StreamGroup if we had the package. 
    // Let's implement a simple combineLatest2 manually or use async expansion.
    
    return StreamBuilderWithCombine(officialStream, personalStream);
  }
}

// Helper to combine two streams manually since we don't have RxDart
Stream<List<Subject>> StreamBuilderWithCombine(
    Stream<List<Subject>> stream1, Stream<List<Subject>> stream2) {
  // We need to emit a new list whenever either stream emits.
  // We'll maintain the latest state of both lists.
  
  // Create a controller to output the combined stream
  // Note: This simple implementation might have issues with broadcast/single-subscription if not careful.
  // But for StreamBuilder it's okay.
  
  final controller = StreamController<List<Subject>>();
  List<Subject> list1 = [];
  List<Subject> list2 = [];
  bool hasEmitted1 = false;
  bool hasEmitted2 = false;

  final sub1 = stream1.listen(
    (data) {
      list1 = data;
      hasEmitted1 = true;
      controller.add([...list1, ...list2]);
    },
    onError: controller.addError,
    onDone: () {
      // Don't close unless both are done? 
      // For Firestore streams, they usually stay open.
    },
  );

  final sub2 = stream2.listen(
    (data) {
      list2 = data;
      hasEmitted2 = true;
      // If stream1 hasn't emitted yet, we still emit stream2
      controller.add([...list1, ...list2]);
    },
    onError: controller.addError,
    onDone: () {},
  );

  controller.onCancel = () {
    sub1.cancel();
    sub2.cancel();
  };

  return controller.stream;
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
