import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/subject.dart';
import '../../services/database_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/date_selector.dart';
import '../../widgets/subject_card.dart';
import '../login_screen.dart';
import 'personal_subject_dialog.dart';
import 'attendance_screen.dart';
import 'faculty_profile_screen.dart';
import '../../services/faculty_service.dart';
import '../../services/attendance_photo_service.dart';
import '../../models/faculty.dart';
import '../admin/admin_dashboard_screen.dart';

class FacultyDashboardScreen extends StatefulWidget {
  final String facultyId;
  final String facultyName;
  final String role; // 'faculty' or 'faculty_admin'
  final String? department;

  const FacultyDashboardScreen({
    super.key,
    required this.facultyId,
    required this.facultyName,
    this.role = 'faculty',
    this.department,
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
          if (widget.role == 'faculty_admin')
            IconButton(
              icon: const Icon(Icons.admin_panel_settings, color: Colors.blue),
              tooltip: 'Admin Panel',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AdminDashboardScreen(
                      restrictedDepartment: widget.department,
                    ),
                  ),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.blue),
            tooltip: 'My Profile',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => FacultyProfileScreen(
                    facultyId: widget.facultyId,
                    facultyName: widget.facultyName,
                    role: widget.role,
                    department: widget.department,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_active, color: Colors.blue),
            tooltip: 'Test Notification',
            onPressed: () async {
              await NotificationService().showTestNotification();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sent test notification! Check status bar.')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black54),
            tooltip: 'Logout',
            onPressed: () async {
              await FacultyService.clearLocalSession();
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
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
                        onTap: lecture.isPersonal 
                            ? () => _showEditNote(context) 
                            : lecture.isProxy 
                                ? () => _showProxyDetails(lecture)
                                : () => _showAttendanceMethodDialog(lecture),
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

  void _showAttendanceMethodDialog(Subject lecture) {
    // Extract semester, division, batch from subject's path context
    String semester = lecture.semester ?? '';
    final division = lecture.division ?? '';
    final batch = lecture.batch ?? '';

    // Normalize "Semester 4" or "Semester4" to just "4"
    semester = semester.replaceAll(RegExp(r'[^0-9]'), '');

    if (semester.isEmpty || division.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot open attendance: missing class info for this subject.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final resolvedBatch = lecture.type == 'lecture'
        ? 'All'
        : (batch.isNotEmpty ? batch : '${division}1');

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                lecture.subjectName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Choose how you want to take attendance',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),

              // Option 1: Manual Attendance
              _buildAttendanceOption(
                icon: Icons.checklist_rounded,
                iconColor: const Color(0xFF7BA5E8),
                title: 'Take Attendance Manually',
                subtitle: 'Mark each student present or absent',
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => AttendanceScreen(
                        subjectId: lecture.id,
                        subjectName: lecture.subjectName,
                        subjectType: lecture.type,
                        semester: semester,
                        division: division,
                        batch: resolvedBatch,
                        facultyId: widget.facultyId,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Option 2: Photo Attendance
              _buildAttendanceOption(
                icon: Icons.camera_alt_rounded,
                iconColor: const Color(0xFFFF9066),
                title: 'Click Attendance Photo',
                subtitle: 'Capture photo of paper attendance sheet',
                onTap: () async {
                  Navigator.pop(ctx);
                  await AttendancePhotoService.captureAndUploadAttendancePhoto(
                    context: context,
                    semester: semester,
                    division: division,
                    batch: resolvedBatch,
                    subjectId: lecture.id,
                    subjectName: lecture.subjectName,
                    facultyId: widget.facultyId,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttendanceOption({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: iconColor.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
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

  void _showProxyDetails(Subject subject) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subject.subjectName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (subject.isProxy)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Text(
                    'Proxy Class (Original: ${subject.originalFacultyName})',
                    style: const TextStyle(color: Colors.orange),
                  ),
                ),
              const SizedBox(height: 24),
              // Proxy assignment is now Admin-only.
              // We only show the details here.
              if (subject.isProxy)
               ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.history, color: Colors.orange),
                  ),
                  title: const Text('Proxy Details'),
                  subtitle: Text('Original: ${subject.originalFacultyName}'),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showProxySelectionDialog(Subject subject) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final allFaculty = await FacultyService.getAllFaculty();
      
      // Remove self from list
      final availableFaculty = allFaculty
          .where((f) => f.facultyId != widget.facultyId)
          .toList();

      if (!mounted) return;
      Navigator.pop(context); // Pop loading

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Proxy Faculty'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: availableFaculty.length,
              itemBuilder: (context, index) {
                final faculty = availableFaculty[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(faculty.facultyName[0]),
                  ),
                  title: Text(faculty.facultyName),
                  subtitle: Text(faculty.facultyId),
                  onTap: () async {
                    Navigator.pop(context); // Pop dialog
                    await _assignProxy(subject, faculty);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) Navigator.pop(context); // Pop loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading faculty: $e')),
        );
      }
    }
  }

  Future<void> _assignProxy(Subject subject, Faculty proxyFaculty) async {
    try {
      await DatabaseService.assignProxy(
        subject,
        proxyFaculty.facultyId,
        proxyFaculty.facultyName,
        widget.facultyName,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Assigned proxy to ${proxyFaculty.facultyName}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error assigning proxy: $e')),
        );
      }
    }
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
    
    return _combineStreams(officialStream, personalStream);
  }

  // Helper to combine two streams manually since we don't have RxDart
  Stream<List<Subject>> _combineStreams(
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
    bool hasEmitted2 = false; // Unused but kept for logic clarity

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
