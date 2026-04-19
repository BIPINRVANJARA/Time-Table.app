import 'package:flutter/material.dart';
import '../../models/faculty.dart';
import '../../services/faculty_service.dart';
import 'faculty_attendance_history_screen.dart';

class FacultyProfileScreen extends StatefulWidget {
  final String facultyId;
  final String facultyName;
  final String role;
  final String? department;

  const FacultyProfileScreen({
    super.key,
    required this.facultyId,
    required this.facultyName,
    required this.role,
    this.department,
  });

  @override
  State<FacultyProfileScreen> createState() => _FacultyProfileScreenState();
}

class _FacultyProfileScreenState extends State<FacultyProfileScreen> {
  Faculty? _faculty;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFacultyDetails();
  }

  Future<void> _loadFacultyDetails() async {
    try {
      final faculty = await FacultyService.getFacultyByFacultyId(widget.facultyId);
      if (mounted) {
        setState(() {
          _faculty = faculty;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text(
          'My Profile',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Avatar & Name Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7BA5E8), Color(0xFF5B8BD6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7BA5E8).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Avatar circle
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.5),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              widget.facultyName.isNotEmpty
                                  ? widget.facultyName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _faculty?.facultyName ?? widget.facultyName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.role == 'faculty_admin' ? 'Faculty Admin' : 'Faculty',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Profile Details Card
                  Container(
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
                        const Text(
                          'Profile Details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4A4A4A),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildDetailRow(
                          icon: Icons.badge_outlined,
                          label: 'Faculty ID',
                          value: _faculty?.facultyId ?? widget.facultyId,
                        ),
                        const Divider(height: 24),
                        _buildDetailRow(
                          icon: Icons.person_outline,
                          label: 'Full Name',
                          value: _faculty?.facultyName ?? widget.facultyName,
                        ),
                        const Divider(height: 24),
                        _buildDetailRow(
                          icon: Icons.business_outlined,
                          label: 'Department',
                          value: _faculty?.department ?? widget.department ?? 'Not assigned',
                        ),
                        const Divider(height: 24),
                        _buildDetailRow(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: _faculty?.email ?? 'Not set',
                        ),
                        const Divider(height: 24),
                        _buildDetailRow(
                          icon: Icons.admin_panel_settings_outlined,
                          label: 'Role',
                          value: (widget.role == 'faculty_admin')
                              ? 'Faculty Admin'
                              : 'Faculty',
                        ),
                        const Divider(height: 24),
                        _buildDetailRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Joined',
                          value: _faculty != null
                              ? _formatDate(_faculty!.createdAt)
                              : 'Unknown',
                        ),
                        const Divider(height: 32),
                        const Text(
                          'Actions',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4A4A4A),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildActionTile(
                          icon: Icons.history_edu_rounded,
                          title: 'Manage Attendance Records',
                          subtitle: 'View, edit, or download CSV reports',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FacultyAttendanceHistoryScreen(
                                  facultyId: widget.facultyId,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF7BA5E8).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF7BA5E8), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF7BA5E8).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF7BA5E8), size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
