import 'package:flutter/material.dart';
import '../../services/college_structure_service.dart';
import '../../services/auth_service.dart';
import 'admin_timetable_editor.dart';
import '../today_schedule_screen.dart';
import 'admin_faculty_list_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String? _selectedBranch;
  String? _selectedSemester;
  String? _selectedDivision;
  bool _isCheckingAdmin = true;

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
  }

  Future<void> _checkAdminAccess() async {
    final isAdmin = await AuthService.isAdmin();
    
    if (!isAdmin && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Admin access required'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const TodayScheduleScreen(),
        ),
      );
      return;
    }

    setState(() => _isCheckingAdmin = false);
  }

  void _navigateToEditor() {
    if (_selectedBranch == null ||
        _selectedSemester == null ||
        _selectedDivision == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select all fields')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AdminTimetableEditor(
          branch: _selectedBranch!,
          semester: _selectedSemester!,
          division: _selectedDivision!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: const Color(0xFF7BA5E8),
        foregroundColor: Colors.white,
      ),
      body: _isCheckingAdmin
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildManageFacultySection(),
                      const SizedBox(height: 32),
                      const Text(
                        'Manage Timetables',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4A4A4A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Select a combination to create or modify a schedule.',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 32),
                      _buildSectionTitle('Branch'),
                      _buildDropdown(
                        hint: 'Select Branch',
                        value: _selectedBranch,
                        items: CollegeStructureService.branches,
                        onChanged: (val) => setState(() => _selectedBranch = val),
                      ),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Semester'),
                      _buildDropdown(
                        hint: 'Select Semester',
                        value: _selectedSemester,
                        items: CollegeStructureService.semesters,
                        onChanged: (val) => setState(() => _selectedSemester = val),
                      ),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Division'),
                      _buildDropdown(
                        hint: 'Select Division',
                        value: _selectedDivision,
                        items: CollegeStructureService.divisions,
                        onChanged: (val) => setState(() => _selectedDivision = val),
                      ),
                      const SizedBox(height: 48),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: _navigateToEditor,
                          icon: const Icon(Icons.edit_calendar_rounded),
                          label: const Text(
                            'Manage Timetable',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF9066),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF4A4A4A),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: TextStyle(color: Colors.grey[500])),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildManageFacultySection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.people_alt_rounded, color: Color(0xFF7BA5E8), size: 28),
              SizedBox(width: 12),
              Text(
                'Faculty Management',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A4A4A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Add, edit, or remove faculty members and manage their credentials.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AdminFacultyListScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7BA5E8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text('Manage Faculty'),
            ),
          ),
        ],
      ),
    );
  }
}
