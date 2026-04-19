import 'package:flutter/material.dart';
import '../../models/faculty.dart';
import '../../services/faculty_service.dart';
import 'admin_faculty_schedule_screen.dart';

class AdminProxyManagementScreen extends StatefulWidget {
  final String? restrictedDepartment;

  const AdminProxyManagementScreen({
    super.key,
    this.restrictedDepartment,
  });

  @override
  State<AdminProxyManagementScreen> createState() => _AdminProxyManagementScreenState();
}

class _AdminProxyManagementScreenState extends State<AdminProxyManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Proxies'),
        backgroundColor: const Color(0xFF7BA5E8),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Faculty>>(
        future: FacultyService.getAllFaculty(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          var facultyList = snapshot.data ?? [];
          
          // Filter if restricted
          if (widget.restrictedDepartment != null) {
            facultyList = facultyList
                .where((f) => f.department == widget.restrictedDepartment)
                .toList();
          }

          if (facultyList.isEmpty) {
            return const Center(child: Text('No faculty members found'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: facultyList.length,
            itemBuilder: (context, index) {
              final faculty = facultyList[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF7BA5E8),
                    foregroundColor: Colors.white,
                    child: Text(faculty.facultyName.isNotEmpty ? faculty.facultyName[0].toUpperCase() : '?'),
                  ),
                  title: Text(
                    faculty.facultyName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Text(faculty.facultyId),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminFacultyScheduleScreen(
                          faculty: faculty,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
