import 'package:flutter/material.dart';
import '../../models/faculty.dart';
import '../../models/subject.dart';
import '../../services/database_service.dart';
import '../../services/faculty_service.dart';
import '../../widgets/date_selector.dart';
import '../../widgets/subject_card.dart';

class AdminFacultyScheduleScreen extends StatefulWidget {
  final Faculty faculty; // The "Absent" faculty

  const AdminFacultyScheduleScreen({super.key, required this.faculty});

  @override
  State<AdminFacultyScheduleScreen> createState() => _AdminFacultyScheduleScreenState();
}

class _AdminFacultyScheduleScreenState extends State<AdminFacultyScheduleScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final dayOfWeek = _selectedDate.weekday;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.faculty.facultyName}\'s Schedule'),
        backgroundColor: const Color(0xFF7BA5E8),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFF5F7FA),
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

          // Schedule List
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
                
                // Filter by selected day
                final lectures = allLectures
                    .where((s) => s.dayOfWeek == dayOfWeek)
                    .toList();
                
                // Sort by time
                lectures.sort((a, b) => a.startInMinutes.compareTo(b.startInMinutes));

                if (lectures.isEmpty) {
                  return const Center(
                    child: Text('No lectures scheduled for this day.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: lectures.length,
                  itemBuilder: (context, index) {
                    final lecture = lectures[index];
                    return SubjectCard(
                      key: ValueKey(lecture.id),
                      subject: lecture,
                      // On tap, ADMIN assigns proxy
                      onTap: () => _showProxyOptions(lecture),
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

  Stream<List<Subject>> _streamFacultyLectures() {
    return DatabaseService.streamAllTimetables()
        .map((subjects) => subjects
            .where((s) => s.facultyId == widget.faculty.facultyId)
            .toList());
  }

  void _showProxyOptions(Subject subject) {
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
                'Manage: ${subject.subjectName}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text('Original Faculty: ${widget.faculty.facultyName}'),
              const SizedBox(height: 24),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.person_add, color: Colors.blue),
                ),
                title: const Text('Assign Proxy'),
                subtitle: const Text('Assign another faculty to take this class'),
                onTap: () {
                  Navigator.pop(context);
                  _showProxySelectionDialog(subject);
                },
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
      
      // Remove the absent faculty from the list (can't be their own proxy)
      final availableFaculty = allFaculty
          .where((f) => f.facultyId != widget.faculty.facultyId)
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
                    child: Text(faculty.facultyName.isNotEmpty ? faculty.facultyName[0] : '?'),
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
      // Logic: 
      // originalFacultyName = widget.faculty.facultyName (The absent one)
      // proxyFaculty = The selected replacement
      await DatabaseService.assignProxy(
        subject,
        proxyFaculty.facultyId,
        proxyFaculty.facultyName,
        widget.faculty.facultyName, 
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
}
