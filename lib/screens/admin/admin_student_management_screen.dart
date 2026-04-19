import 'package:flutter/material.dart';
import '../../models/student.dart';
import '../../services/student_service.dart';
import '../../services/college_structure_service.dart';
import 'admin_add_student_screen.dart';
import 'admin_student_import_screen.dart';

class AdminStudentManagementScreen extends StatefulWidget {
  final String? restrictedDepartment;

  const AdminStudentManagementScreen({
    super.key,
    this.restrictedDepartment,
  });

  @override
  State<AdminStudentManagementScreen> createState() =>
      _AdminStudentManagementScreenState();
}

class _AdminStudentManagementScreenState
    extends State<AdminStudentManagementScreen> {
  String? _selectedSemester;
  String? _selectedDivision;
  String? _selectedBatch;
  bool _showStudentList = false;

  // Track first-time warning per student
  final Set<String> _warnedStudentIds = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Management'),
        backgroundColor: const Color(0xFF7BA5E8),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload_outlined),
            tooltip: 'Import students (JSON)',
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AdminStudentImportScreen(
                    initialSemester: _selectedSemester,
                    initialDivision: _selectedDivision,
                  ),
                ),
              );
              
              if (result == true && _showStudentList) {
                // Refresh list if we are currently looking at one
                _loadStudents();
              }
            },
          ),
          if (_showStudentList && _selectedSemester != null)
            IconButton(
              icon: const Icon(Icons.arrow_upward_rounded),
              tooltip: 'Promote Term',
              onPressed: _showPromoteDialog,
            ),
        ],
      ),
      floatingActionButton: _showStudentList
          ? FloatingActionButton(
              onPressed: _navigateToAddStudent,
              backgroundColor: const Color(0xFF7BA5E8),
              child: const Icon(Icons.person_add),
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSelectionCard(),
            if (_showStudentList) ...[
              const SizedBox(height: 24),
              _buildStudentList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionCard() {
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
              Icon(Icons.school_rounded, color: Color(0xFF7BA5E8), size: 28),
              SizedBox(width: 12),
              Text(
                'Select Class',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A4A4A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Choose semester, division, and batch to manage students.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 20),

          // Semester Dropdown
          _buildLabel('Semester'),
          _buildDropdown(
            hint: 'Select Semester',
            value: _selectedSemester,
            items: List.generate(6, (i) => '${i + 1}'),
            onChanged: (val) => setState(() {
              _selectedSemester = val;
              _selectedBatch = null;
              _showStudentList = false;
            }),
          ),
          const SizedBox(height: 16),

          // Division Dropdown
          _buildLabel('Division'),
          _buildDropdown(
            hint: 'Select Division',
            value: _selectedDivision,
            items: CollegeStructureService.divisions,
            onChanged: (val) => setState(() {
              _selectedDivision = val;
              _selectedBatch = null;
              _showStudentList = false;
            }),
          ),
          const SizedBox(height: 16),

          // Batch Dropdown
          _buildLabel('Batch'),
          _buildDropdown(
            hint: 'Select Batch',
            value: _selectedBatch,
            items: _selectedDivision != null
                ? CollegeStructureService.getBatchesForDivision(
                    _selectedDivision!)
                : [],
            onChanged: (val) => setState(() {
              _selectedBatch = val;
              _showStudentList = false;
            }),
          ),
          const SizedBox(height: 24),

          // Load Students Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _canLoad() ? _loadStudents : null,
              icon: const Icon(Icons.search),
              label: const Text('Load Students',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9066),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canLoad() {
    return _selectedSemester != null &&
        _selectedDivision != null &&
        _selectedBatch != null;
  }

  void _loadStudents() {
    setState(() {
      _showStudentList = true;
      _warnedStudentIds.clear();
    });
  }

  Widget _buildStudentList() {
    return StreamBuilder<List<Student>>(
      stream: StudentService.streamStudents(
        _selectedSemester!,
        _selectedDivision!,
        _selectedBatch!,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final students = snapshot.data ?? [];

        if (students.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(40),
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
              children: [
                Icon(Icons.person_off_rounded,
                    size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                const Text(
                  'No students found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sem $_selectedSemester | Div $_selectedDivision | Batch $_selectedBatch',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tap the + button to add students.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Students (${students.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A4A4A),
                  ),
                ),
                const Spacer(),
                Text(
                  'Sem $_selectedSemester | $_selectedDivision | $_selectedBatch',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...students.map((student) => _buildStudentCard(student)),
          ],
        );
      },
    );
  }

  Widget _buildStudentCard(Student student) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Sr Number badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF7BA5E8).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '${student.srNumber}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF7BA5E8),
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Name and enrollment
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        student.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ),
                    if (student.linkedEmail != null && student.linkedEmail!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.link, size: 12, color: Colors.green),
                            SizedBox(width: 2),
                            Text(
                              'Linked',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  student.enrollmentNumber,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          // Link account button
          IconButton(
            icon: Icon(
              student.linkedEmail != null && student.linkedEmail!.isNotEmpty
                  ? Icons.link
                  : Icons.link_off,
              color: student.linkedEmail != null && student.linkedEmail!.isNotEmpty
                  ? Colors.green
                  : Colors.grey[400],
              size: 20,
            ),
            tooltip: student.linkedEmail != null && student.linkedEmail!.isNotEmpty
                ? 'Linked: ${student.linkedEmail}'
                : 'Link student account',
            onPressed: () => _showLinkAccountDialog(student),
          ),
          // Delete button
          IconButton(
            icon: Icon(
              _warnedStudentIds.contains(student.id)
                  ? Icons.delete_forever
                  : Icons.delete_outline,
              color: _warnedStudentIds.contains(student.id)
                  ? Colors.red
                  : Colors.grey,
            ),
            tooltip: _warnedStudentIds.contains(student.id)
                ? 'Tap again to confirm removal'
                : 'Remove student',
            onPressed: () => _handleRemoveStudent(student),
          ),
        ],
      ),
    );
  }

  void _handleRemoveStudent(Student student) async {
    if (!_warnedStudentIds.contains(student.id)) {
      // First click: show warning
      setState(() {
        _warnedStudentIds.add(student.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '⚠️ Warning: Tap delete again to permanently remove ${student.name}',
          ),
          backgroundColor: Colors.orange[700],
          duration: const Duration(seconds: 3),
        ),
      );
      // Auto-reset warning after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _warnedStudentIds.remove(student.id);
          });
        }
      });
      return;
    }

    // Second click: confirm dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Student'),
        content: Text(
          'Are you sure you want to permanently remove ${student.name} (${student.enrollmentNumber})?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child:
                const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await StudentService.removeStudent(
          _selectedSemester!,
          _selectedDivision!,
          _selectedBatch!,
          student.id,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('${student.name} removed successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
    setState(() {
      _warnedStudentIds.remove(student.id);
    });
  }

  void _navigateToAddStudent() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AdminAddStudentScreen(
          semester: _selectedSemester!,
          division: _selectedDivision!,
          batch: _selectedBatch!,
        ),
      ),
    );
  }

  void _showLinkAccountDialog(Student student) {
    final emailController = TextEditingController(
      text: student.linkedEmail ?? '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.link_rounded, color: Color(0xFF7BA5E8)),
            SizedBox(width: 8),
            Text('Link Student Account'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              student.name,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            Text(
              student.enrollmentNumber,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            const Text(
              'Enter the student\'s email to link their account. This allows the student to track their own attendance.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'student@email.com',
                prefixIcon: const Icon(Icons.email_outlined),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF7BA5E8), width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (student.linkedEmail != null && student.linkedEmail!.isNotEmpty)
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                try {
                  await StudentService.updateStudentField(
                    _selectedSemester!,
                    _selectedDivision!,
                    _selectedBatch!,
                    student.id,
                    'linkedEmail',
                    null,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Unlinked ${student.name}\'s account'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('Unlink', style: TextStyle(color: Colors.orange)),
            ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty || !email.contains('@')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid email'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              Navigator.of(ctx).pop();
              try {
                await StudentService.updateStudentField(
                  _selectedSemester!,
                  _selectedDivision!,
                  _selectedBatch!,
                  student.id,
                  'linkedEmail',
                  email,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Linked ${student.name} to $email'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7BA5E8),
              foregroundColor: Colors.white,
            ),
            child: const Text('Link Account'),
          ),
        ],
      ),
    );
    
    // Dispose the controller when dialog is dismissed
    // (AlertDialog will handle it when popped)
  }

  void _showPromoteDialog() {
    final fromNum =
        int.tryParse(_selectedSemester!.replaceAll(RegExp(r'[^0-9]'), ''));
    if (fromNum == null || fromNum >= 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot promote beyond Semester 8'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final toSem = fromNum + 1;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Promote Term'),
        content: Text(
          'This will copy ALL students from Semester $fromNum → Semester $toSem '
          '(across all divisions and batches).\n\n'
          '• Existing data in Semester $toSem will NOT be deleted.\n'
          '• Detained students should be deleted manually from Semester $toSem afterward.\n\n'
          'Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _performPromotion(_selectedSemester!);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF9066),
              foregroundColor: Colors.white,
            ),
            child: const Text('Promote'),
          ),
        ],
      ),
    );
  }

  Future<void> _performPromotion(String fromSemester) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final count = await StudentService.promoteStudents(fromSemester);
      if (mounted) {
        Navigator.pop(context); // pop loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Promoted $count students successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // pop loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 2),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
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
    required void Function(String?)? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
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
}
