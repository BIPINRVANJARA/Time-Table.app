import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/college_structure_service.dart';
import '../services/database_service.dart';
import '../models/user_model.dart';
import 'today_schedule_screen.dart';

class AcademicSetupScreen extends StatefulWidget {
  const AcademicSetupScreen({super.key});

  @override
  State<AcademicSetupScreen> createState() => _AcademicSetupScreenState();
}

class _AcademicSetupScreenState extends State<AcademicSetupScreen> {
  String? _selectedBranch;
  String? _selectedSemester;
  String? _selectedDivision;
  String? _selectedBatch;
  bool _isLoading = false;

  Future<void> _saveProfile() async {
    if (_selectedBranch == null ||
        _selectedSemester == null ||
        _selectedDivision == null ||
        _selectedBatch == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select all fields')),
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

      final userModel = UserModel(
        uid: user.uid,
        email: user.email ?? '',
        role: currentRole,
        branch: _selectedBranch!,
        semester: _selectedSemester!,
        division: _selectedDivision!,
        batch: _selectedBatch!,
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
              const Text(
                'Academic Setup',
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
                                : const Text(
                                    'Continue',
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
}

