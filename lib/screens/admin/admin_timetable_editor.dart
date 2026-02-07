import 'package:flutter/material.dart';
import '../../models/subject.dart';
import '../../services/database_service.dart';
import '../../widgets/subject_card.dart';
import 'admin_subject_form_screen.dart';

class AdminTimetableEditor extends StatefulWidget {
  final String branch;
  final String semester;
  final String division;

  const AdminTimetableEditor({
    super.key,
    required this.branch,
    required this.semester,
    required this.division,
  });

  @override
  State<AdminTimetableEditor> createState() => _AdminTimetableEditorState();
}

class _AdminTimetableEditorState extends State<AdminTimetableEditor> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _addSubject() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AdminSubjectFormScreen(
          branch: widget.branch,
          semester: widget.semester,
          division: widget.division,
          dayOfWeek: _tabController.index + 1,
        ),
      ),
    );
  }

  void _editSubject(Subject subject) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AdminSubjectFormScreen(
          branch: widget.branch,
          semester: widget.semester,
          division: widget.division,
          subject: subject,
        ),
      ),
    );
  }

  Future<void> _deleteSubject(Subject subject) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subject?'),
        content: Text('Are you sure you want to delete ${subject.subjectName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseService.deleteSubject(
        widget.branch,
        widget.semester,
        widget.division,
        subject.id,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.branch} - Div ${widget.division}'),
        backgroundColor: const Color(0xFF7BA5E8),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: _days.map((day) => Tab(text: day)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(7, (index) {
          final dayOfWeek = index + 1;
          return StreamBuilder<List<Subject>>(
            stream: DatabaseService.streamTimetable(widget.branch, widget.semester, widget.division),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final allSubjects = snapshot.data ?? [];
              final daySubjects = allSubjects.where((s) => s.dayOfWeek == dayOfWeek).toList();
              daySubjects.sort((a, b) => a.startInMinutes.compareTo(b.startInMinutes));

              if (daySubjects.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.event_note, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text('No classes for ${_days[index]}'),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: daySubjects.length,
                itemBuilder: (context, idx) {
                  final subject = daySubjects[idx];
                  return SubjectCard(
                    subject: subject,
                    onTap: () => _editSubject(subject),
                    onDelete: () => _deleteSubject(subject),
                  );
                },
              );
            },
          );
        }),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addSubject,
        backgroundColor: const Color(0xFFFF9066),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
