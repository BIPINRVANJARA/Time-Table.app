import 'package:flutter/material.dart';
import '../../models/student.dart';
import '../../services/student_service.dart';

class AdminAddStudentScreen extends StatefulWidget {
  final String semester;
  final String division;
  final String batch;

  const AdminAddStudentScreen({
    super.key,
    required this.semester,
    required this.division,
    required this.batch,
  });

  @override
  State<AdminAddStudentScreen> createState() => _AdminAddStudentScreenState();
}

class _AdminAddStudentScreenState extends State<AdminAddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _srNumberController = TextEditingController();
  final _nameController = TextEditingController();
  final _enrollmentController = TextEditingController();
  final _linkedEmailController = TextEditingController();
  bool _isLoading = false;
  bool _linkAccount = false;

  @override
  void dispose() {
    _srNumberController.dispose();
    _nameController.dispose();
    _enrollmentController.dispose();
    _linkedEmailController.dispose();
    super.dispose();
  }

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final student = Student(
        id: '',
        srNumber: int.parse(_srNumberController.text.trim()),
        name: _nameController.text.trim(),
        enrollmentNumber: _enrollmentController.text.trim(),
        semester: widget.semester,
        division: widget.division,
        batch: widget.batch,
        linkedEmail: _linkAccount && _linkedEmailController.text.trim().isNotEmpty
            ? _linkedEmailController.text.trim()
            : null,
      );

      await StudentService.addStudent(
        widget.semester,
        widget.division,
        widget.batch,
        student,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${student.name} added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Clear form for next entry
        _srNumberController.clear();
        _nameController.clear();
        _enrollmentController.clear();
        _linkedEmailController.clear();
        setState(() => _linkAccount = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Student'),
        backgroundColor: const Color(0xFF7BA5E8),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Class info header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7BA5E8).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF7BA5E8).withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.class_rounded,
                          color: Color(0xFF7BA5E8)),
                      const SizedBox(width: 12),
                      Text(
                        'Sem ${widget.semester} | Div ${widget.division} | Batch ${widget.batch}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF7BA5E8),
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Form
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Sr Number'),
                      TextFormField(
                        controller: _srNumberController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration('Enter serial number'),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Sr number is required';
                          }
                          if (int.tryParse(val.trim()) == null) {
                            return 'Enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      _buildLabel('Student Name'),
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: _inputDecoration('Enter full name'),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      _buildLabel('Enrollment Number'),
                      TextFormField(
                        controller: _enrollmentController,
                        decoration:
                            _inputDecoration('Enter enrollment number'),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Enrollment number is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Link Student Account toggle
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _linkAccount
                              ? Colors.green.withOpacity(0.05)
                              : Colors.grey[50],
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _linkAccount
                                ? Colors.green.withOpacity(0.3)
                                : Colors.grey[300]!,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.link_rounded,
                                  color: _linkAccount
                                      ? Colors.green
                                      : Colors.grey[500],
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Link Student Account',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: Color(0xFF333333),
                                        ),
                                      ),
                                      Text(
                                        'Student can track their own attendance',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: _linkAccount,
                                  activeColor: Colors.green,
                                  onChanged: (val) =>
                                      setState(() => _linkAccount = val),
                                ),
                              ],
                            ),
                            if (_linkAccount) ...[
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _linkedEmailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: _inputDecoration(
                                    'Enter student email address'),
                                validator: (val) {
                                  if (_linkAccount &&
                                      (val == null || val.trim().isEmpty)) {
                                    return 'Email is required when linking account';
                                  }
                                  if (_linkAccount &&
                                      val != null &&
                                      !val.contains('@')) {
                                    return 'Enter a valid email address';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Save button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveStudent,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7BA5E8),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey[300],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Add Student',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400]),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
