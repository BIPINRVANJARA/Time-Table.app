import 'package:flutter/material.dart';
import '../../services/faculty_service.dart';
import '../../models/faculty.dart';

class AdminFacultyFormScreen extends StatefulWidget {
  final Faculty? faculty;

  const AdminFacultyFormScreen({super.key, this.faculty});

  @override
  State<AdminFacultyFormScreen> createState() => _AdminFacultyFormScreenState();
}

class _AdminFacultyFormScreenState extends State<AdminFacultyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _idController;
  late TextEditingController _passwordController;
  late TextEditingController _departmentController;
  late TextEditingController _emailController;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.faculty?.facultyName ?? '');
    _idController = TextEditingController(text: widget.faculty?.facultyId ?? '');
    _passwordController = TextEditingController(); // Start empty for edit
    _departmentController = TextEditingController(text: widget.faculty?.department ?? '');
    _emailController = TextEditingController(text: widget.faculty?.email ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _passwordController.dispose();
    _departmentController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Check password requirement for new faculty
    if (widget.faculty == null && _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password is required for new faculty')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.faculty == null) {
        // Create new
        await FacultyService.createFaculty(
          facultyId: null, // Auto-generate
          facultyName: _nameController.text.trim(),
          password: _passwordController.text,
          department: _departmentController.text.trim().isEmpty ? null : _departmentController.text.trim(),
          email: _emailController.text.trim(), // Validated as required
        );
      } else {
        // Update existing info
        final updatedFaculty = Faculty(
          id: widget.faculty!.id,
          facultyId: _idController.text.trim(),
          facultyName: _nameController.text.trim(),
          passwordHash: widget.faculty!.passwordHash, // Keep existing hash
          department: _departmentController.text.trim().isEmpty ? null : _departmentController.text.trim(),
          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          createdAt: widget.faculty!.createdAt,
        );
        
        await FacultyService.updateFaculty(updatedFaculty);

        // Update password if provided
        if (_passwordController.text.isNotEmpty) {
          await FacultyService.updatePassword(widget.faculty!.facultyId, _passwordController.text);
        }
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Faculty saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.faculty != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Faculty' : 'Add Faculty'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _save,
            icon: _isLoading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.check),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF5F7FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Basic Info Card
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          hintText: 'e.g., Vaishali Sharma',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                        TextFormField(
                          controller: _idController,
                          // Disable editing ID for new faculty (auto-generated) AND existing faculty (immutable)
                          enabled: false, 
                          decoration: InputDecoration(
                            labelText: 'Faculty ID',
                            hintText: isEditing ? '' : 'Auto-generated (e.g., FAC001)',
                            prefixIcon: const Icon(Icons.badge),
                            border: const OutlineInputBorder(),
                            helperText: isEditing ? null : 'ID will be assigned automatically',
                          ),
                          // ID is not required from UI for new faculty
                          validator: (v) => isEditing && (v == null || v.isEmpty) ? 'Required' : null,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Department & Contact
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _departmentController,
                        decoration: const InputDecoration(
                          labelText: 'Department (Optional)',
                          hintText: 'e.g., IT, Computer, Civil',
                          prefixIcon: Icon(Icons.business),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email (Required)',
                            hintText: 'e.g., faculty@college.edu',
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(),
                            helperText: 'Required for password reset',
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Email is required';
                            if (!v.contains('@')) return 'Invalid email address';
                            return null;
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Security
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEditing ? 'Change Password (Optional)' : 'Set Password',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          border: const OutlineInputBorder(),
                          helperText: isEditing ? 'Leave blank to keep current password' : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
