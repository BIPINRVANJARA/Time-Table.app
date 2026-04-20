import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/college_structure_service.dart';
import '../services/database_service.dart';
import '../models/user_model.dart';
import 'today_schedule_screen.dart';

class AcademicSetupScreen extends StatefulWidget {
  final UserModel? userModel;
  
  const AcademicSetupScreen({super.key, this.userModel});

  @override
  State<AcademicSetupScreen> createState() => _AcademicSetupScreenState();
}

class _AcademicSetupScreenState extends State<AcademicSetupScreen> {
  String? _selectedBranch;
  String? _selectedSemester;
  String? _selectedDivision;
  String? _selectedBatch;
  final TextEditingController _enrollmentController = TextEditingController();
  bool _isLoading = false;
  String _userRole = 'student';
  bool _isEnrollmentLocked = false;

  @override
  void initState() {
    super.initState();
    if (widget.userModel != null) {
      _selectedBranch = widget.userModel!.branch;
      _selectedSemester = widget.userModel!.semester;
      _selectedDivision = widget.userModel!.division;
      _selectedBatch = widget.userModel!.batch;
      _enrollmentController.text = widget.userModel!.enrollmentNumber ?? '';
      _userRole = widget.userModel!.role;
      // Lock enrollment if already set (prevent changing to another student's number)
      _isEnrollmentLocked = widget.userModel!.enrollmentNumber != null && 
          widget.userModel!.enrollmentNumber!.isNotEmpty;
    } else {
      _loadUserRole();
    }
  }

  Future<void> _loadUserRole() async {
    final profile = await DatabaseService.getUserProfile();
    if (profile != null && mounted) {
      setState(() {
        _userRole = profile.role;
        _enrollmentController.text = profile.enrollmentNumber ?? '';
      });
    }
  }

  @override
  void dispose() {
    _enrollmentController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_selectedBranch == null ||
        _selectedSemester == null ||
        _selectedDivision == null ||
        _selectedBatch == null ||
        (_userRole == 'student' && _enrollmentController.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_userRole == 'student' 
            ? 'Please fill all fields including Enrollment Number' 
            : 'Please select all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No user logged in');

      // Fetch existing profile to preserve role if it exists
      final existingProfile = await DatabaseService.getUserProfile();
      final currentRole = existingProfile?.role ?? 'student';

      if (_userRole == 'student') {
        final enrollmentNo = _enrollmentController.text.trim();
        
        // 1. Check if enrollment number exists in the student list for this group
        // Normalize semester (e.g., 'Semester 4' -> '4') to match how students are stored
        final semNum = CollegeStructureService.getSemesterNumber(_selectedSemester!);
        final groupId = '${semNum}_${_selectedDivision}_${_selectedBatch}'.replaceAll(' ', '');
        
        final studentCheck = await FirebaseFirestore.instance
            .collection('students')
            .doc(groupId)
            .collection('entries')
            .where('enrollmentNumber', isEqualTo: enrollmentNo)
            .limit(1)
            .get();
            
        if (studentCheck.docs.isEmpty) {
          throw Exception('Enrollment number $enrollmentNo not found in the official list for the selected division/batch. Please contact admin.');
        }

        // 2. Check if this enrollment number is already linked to ANOTHER user
        final duplicateCheck = await FirebaseFirestore.instance
            .collection('users')
            .where('enrollmentNumber', isEqualTo: enrollmentNo)
            .get();
            
        final otherUsers = duplicateCheck.docs.where((doc) => doc.id != user.uid);
        if (otherUsers.isNotEmpty) {
          throw Exception('This enrollment number is already linked to another account.');
        }
      }

      final userModel = UserModel(
        uid: user.uid,
        email: user.email ?? '',
        role: currentRole,
        branch: _selectedBranch!,
        semester: _selectedSemester!,
        division: _selectedDivision!,
        batch: _selectedBatch!,
        enrollmentNumber: _userRole == 'student' ? _enrollmentController.text.trim() : null,
        createdAt: existingProfile?.createdAt ?? DateTime.now(),
      );

      await DatabaseService.updateUserProfile(userModel);

      if (mounted) {
        // Navigate to Home Screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const TodayScheduleScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF7BA5E8),
              const Color(0xFF9DBEF5),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 32),
              const Icon(
                Icons.school_rounded,
                size: 64,
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              Text(
                widget.userModel != null ? 'Edit Profile' : 'Academic Setup',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                child: Text(
                  'Select your academic details to fetch your personalized timetable',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_userRole == 'student') ...[
                          _buildSectionTitle('Enrollment Number'),
                          _buildTextField(
                            controller: _enrollmentController,
                            hint: 'Enter your enrollment number',
                            icon: _isEnrollmentLocked ? Icons.lock_outline : Icons.badge_outlined,
                            readOnly: _isEnrollmentLocked,
                          ),
                          if (_isEnrollmentLocked)
                            Padding(
                              padding: const EdgeInsets.only(top: 6, left: 4),
                              child: Text(
                                'Enrollment number cannot be changed after registration',
                                style: TextStyle(color: Colors.grey[500], fontSize: 12, fontStyle: FontStyle.italic),
                              ),
                            ),
                          const SizedBox(height: 24),
                        ],
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
                          onChanged: (val) {
                            setState(() {
                              _selectedDivision = val;
                              _selectedBatch = null; // Reset batch when division changes
                            });
                          },
                        ),
                        const SizedBox(height: 24),
                        
                        _buildSectionTitle('Batch'),
                        _buildDropdown(
                          hint: 'Select Batch',
                          value: _selectedBatch,
                          items: _selectedDivision == null 
                              ? [] 
                              : CollegeStructureService.getBatchesForDivision(_selectedDivision!),
                          onChanged: (val) => setState(() => _selectedBatch = val),
                        ),
                        const SizedBox(height: 48),

                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF9066),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                              elevation: 2,
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Text(
                                    widget.userModel != null ? 'Save Changes' : 'Continue',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool readOnly = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: readOnly ? Colors.grey[200] : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: readOnly ? Colors.grey[400]! : Colors.grey[300]!),
      ),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        style: TextStyle(
          color: readOnly ? Colors.grey[600] : Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: Icon(icon, color: readOnly ? Colors.grey[500] : Colors.grey[600], size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}

