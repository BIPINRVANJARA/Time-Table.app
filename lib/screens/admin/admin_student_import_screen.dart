import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/student.dart';
import '../../services/student_service.dart';
import '../../services/college_structure_service.dart';

class AdminStudentImportScreen extends StatefulWidget {
  final String? initialSemester;
  final String? initialDivision;

  const AdminStudentImportScreen({
    super.key,
    this.initialSemester,
    this.initialDivision,
  });

  @override
  State<AdminStudentImportScreen> createState() => _AdminStudentImportScreenState();
}

class _AdminStudentImportScreenState extends State<AdminStudentImportScreen> {
  final TextEditingController _jsonController = TextEditingController();
  String? _selectedSemester;
  String? _selectedDivision;
  bool _isImporting = false;
  List<Map<String, dynamic>>? _parsedStudents;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedSemester = widget.initialSemester;
    _selectedDivision = widget.initialDivision;
  }

  void _validateJson() {
    setState(() {
      _error = null;
      _parsedStudents = null;
    });

    if (_jsonController.text.trim().isEmpty) return;

    try {
      final decoded = json.decode(_jsonController.text.trim());
      List<dynamic> studentList = [];

      if (decoded is List) {
        studentList = decoded;
      } else if (decoded is Map) {
        // Handle nested format { "students": [...] }
        if (decoded.containsKey('students') && decoded['students'] is List) {
          studentList = decoded['students'];
        } else {
          throw Exception('JSON must be a list of students or a map containing a "students" list.');
        }
        
        // Auto-detect semester if present in top level
        if (decoded.containsKey('semester')) {
          final semStr = decoded['semester'].toString();
          if (CollegeStructureService.semesters.contains(semStr)) {
            setState(() => _selectedSemester = semStr);
          }
        }
      }

      final List<Map<String, dynamic>> validated = [];
      for (var item in studentList) {
        if (item is Map<String, dynamic>) {
          // Check for mandatory fields
          if (!item.containsKey('enrollment_no') && !item.containsKey('enrollmentNo')) {
             throw Exception('Student missing enrollment_no');
          }
          if (!item.containsKey('name')) {
             throw Exception('Student missing name');
          }
          
          // Normalize keys
          final normalized = <String, dynamic>{
            'sr_no': item['sr_no'] ?? item['srNo'] ?? 0,
            'enrollment_no': item['enrollment_no'] ?? item['enrollmentNo'],
            'name': item['name'],
            'division': item['division'] ?? item['class']?.toString().replaceAll('DIV', '').trim() ?? _selectedDivision,
            'batch': item['batch'] ?? 'A1', // Default if missing
          };
          
          if (normalized['division'] == null) {
            final studentName = normalized['name'];
            throw Exception('Division missing for student $studentName. Please select a global division or include it in JSON.');
          }
          
          validated.add(normalized);
        }
      }

      setState(() {
        _parsedStudents = validated;
      });
    } catch (e) {
      setState(() {
        _error = 'Invalid JSON format: \$e';
      });
    }
  }

  Future<void> _performImport() async {
    if (_parsedStudents == null || _selectedSemester == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select semester and provide valid JSON')),
      );
      return;
    }

    setState(() => _isImporting = true);

    try {
      final count = await StudentService.bulkAddStudents(_selectedSemester!, _parsedStudents!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully imported $count students to Semester $_selectedSemester!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Return success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulk Student Import'),
        backgroundColor: const Color(0xFF7BA5E8),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Import students from JSON format.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Paste your student list below. Format should be a list of students or a map containing a "students" key.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            
            _buildDropdown(
              hint: 'Select Target Semester',
              value: _selectedSemester,
              items: CollegeStructureService.semesters,
              onChanged: (val) => setState(() => _selectedSemester = val),
            ),
            const SizedBox(height: 16),
            
             _buildDropdown(
              hint: 'Select Default Division (if not in JSON)',
              value: _selectedDivision,
              items: CollegeStructureService.divisions,
              onChanged: (val) => setState(() => _selectedDivision = val),
            ),
            const SizedBox(height: 24),

            TextField(
              controller: _jsonController,
              maxLines: 12,
              decoration: InputDecoration(
                hintText: 'Paste JSON here...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (_) => _validateJson(),
            ),
            
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
            ],
            
            if (_parsedStudents != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 12),
                    Text(
                      'Found ${_parsedStudents!.length} students ready to import.',
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 32),
            
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: (_isImporting || _parsedStudents == null || _selectedSemester == null)
                    ? null
                    : _performImport,
                icon: _isImporting 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.upload_rounded),
                label: Text(_isImporting ? 'Importing...' : 'Start Import'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7BA5E8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(hint, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
