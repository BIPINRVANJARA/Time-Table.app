import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/student.dart';
import '../../models/attendance_record.dart';
import '../../services/student_service.dart';
import '../../services/attendance_service.dart';
import '../../services/database_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceScreen extends StatefulWidget {
  final String subjectId;
  final String subjectName;
  final String subjectType; // 'lecture' or 'lab'
  final String semester;
  final String division;
  final String batch;
  final String facultyId;
  final DateTime? initialDate;

  const AttendanceScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
    required this.subjectType,
    required this.semester,
    required this.division,
    required this.batch,
    required this.facultyId,
    this.initialDate,
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isHoliday = false;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isExporting = false;
  List<Student> _students = [];
  Map<String, bool?> _attendance = {}; // enrollmentNumber -> null(unmarked)/true(present)/false(absent)
  bool _hasExistingRecord = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialDate != null) {
      _selectedDate = widget.initialDate!;
    }
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load students
      final isLecture = widget.subjectType == 'lecture' || 
                       widget.batch == 'All' || 
                       widget.batch == 'ALL' || 
                       widget.batch.isEmpty;

      if (isLecture) {
        _students = await StudentService.getAllStudentsInDivision(
          widget.semester,
          widget.division,
        );
      } else {
        _students = await StudentService.getStudents(
          widget.semester,
          widget.division,
          widget.batch,
        );
      }

      // Load existing attendance for this date
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final existing = await AttendanceService.getAttendance(
        widget.semester,
        widget.division,
        widget.batch,
        widget.subjectId,
        dateStr,
      );

      if (existing != null) {
        _attendance = Map.from(existing.records);
        _isHoliday = existing.isHoliday;
        _hasExistingRecord = true;
      } else {
        // Default: unmarked (faculty must explicitly choose)
        _attendance = {
          for (var s in _students) s.enrollmentNumber: null,
        };
        _isHoliday = false;
        _hasExistingRecord = false;
      }
    } catch (e) {
      if (mounted) {
        // Extract URL from error message if present
        String? indexUrl;
        if (e.toString().contains('https://console.firebase.google.com')) {
          final RegExp regExp = RegExp(r'(https://console\.firebase\.google\.com[^\s]+)');
          final Iterable<Match> matches = regExp.allMatches(e.toString());
          if (matches.isNotEmpty) {
            indexUrl = matches.first.group(0);
          }
        }

        if (indexUrl != null) {
          _showIndexErrorState(indexUrl);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading data: $e')),
          );
        }
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _showIndexErrorState(String url) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.storage_rounded, size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            const Text('Database Index Required', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
              'Your attendance database for Lectures is being prepared. To speed this up, click the button below to authorize the database index.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: url));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Index link copied! Paste it in your browser.'))
                  );
                },
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Copy Index Link'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveAttendance() async {
    // Validate: all students must be marked (unless holiday)
    if (!_isHoliday) {
      final unmarkedCount = _attendance.values.where((v) => v == null).length;
      if (unmarkedCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ $unmarkedCount student(s) not marked yet. Please mark all students.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

      if (_isHoliday) {
        await AttendanceService.markHoliday(
          widget.semester,
          widget.division,
          widget.batch,
          widget.subjectId,
          widget.subjectName,
          dateStr,
          widget.facultyId,
        );
      } else {
        // Convert nullable map to non-nullable (all validated above)
        final finalRecords = _attendance.map((k, v) => MapEntry(k, v ?? false));
        final record = AttendanceRecord(
          date: dateStr,
          subjectId: widget.subjectId,
          subjectName: widget.subjectName,
          semester: widget.semester,
          division: widget.division,
          batch: widget.batch,
          isHoliday: false,
          records: finalRecords,
          facultyId: widget.facultyId,
          markedAt: DateTime.now(),
        );
        await AttendanceService.saveAttendance(record);
      }

      _hasExistingRecord = true;

      if (mounted) {
        final totalPresent =
            _attendance.values.where((v) => v == true).length;
        final totalAbsent =
            _attendance.values.where((v) => v == false).length;

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  _isHoliday ? Icons.beach_access : Icons.check_circle,
                  color: _isHoliday ? Colors.orange : Colors.green,
                ),
                const SizedBox(width: 8),
                Text(_isHoliday ? 'Holiday Marked' : 'Attendance Saved'),
              ],
            ),
            content: _isHoliday
                ? Text(
                    '${DateFormat('dd MMM yyyy').format(_selectedDate)} has been marked as a holiday.')
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('dd MMM yyyy, EEEE')
                            .format(_selectedDate),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      _buildSummaryRow('Present', totalPresent, Colors.green),
                      const SizedBox(height: 6),
                      _buildSummaryRow('Absent', totalAbsent, Colors.red),
                      const Divider(),
                      _buildSummaryRow(
                          'Total', _students.length, Colors.blue),
                    ],
                  ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e'), backgroundColor: Colors.red),
        );
      }
    }

    if (mounted) setState(() => _isSaving = false);
  }

  Widget _buildSummaryRow(String label, int count, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        Text('$count',
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF7BA5E8),
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() => _selectedDate = date);
      _loadData();
    }
  }

  Future<void> _exportAttendance() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF7BA5E8),
            ),
          ),
          child: child!,
        );
      },
    );

    if (range == null) return;

    setState(() => _isExporting = true);

    try {
      final startDateStr = DateFormat('yyyy-MM-dd').format(range.start);
      final endDateStr = DateFormat('yyyy-MM-dd').format(range.end);

      final csv = await AttendanceService.exportAttendanceCSV(
        widget.subjectType,
        widget.semester,
        widget.division,
        widget.batch,
        widget.subjectId,
        widget.subjectName,
        startDate: startDateStr,
        endDate: endDateStr,
      );

      if (csv == 'No attendance records found.') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No attendance records to export.')),
          );
        }
        setState(() => _isExporting = false);
        return;
      }

      // Create a temporary file to share as a real .csv
      final tempDir = await getTemporaryDirectory();
      final fileName = '${widget.subjectName.replaceAll(' ', '_')}_Attendance.csv';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(csv);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Attendance Report - ${widget.subjectName}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export error: $e'), backgroundColor: Colors.red),
        );
      }
    }

    if (mounted) setState(() => _isExporting = false);
  }

  @override
  Widget build(BuildContext context) {
    final totalPresent = _attendance.values.where((v) => v == true).length;
    final totalAbsent = _attendance.values.where((v) => v == false).length;
    final totalUnmarked = _attendance.values.where((v) => v == null).length;
    final isToday = DateFormat('yyyy-MM-dd').format(_selectedDate) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.subjectName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Text(
              widget.subjectType == 'lecture'
                  ? 'Sem ${widget.semester} | ${widget.division} | All'
                  : 'Sem ${widget.semester} | ${widget.division} | ${widget.batch}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Export Attendance (CSV)',
            onPressed: _isExporting ? null : _exportAttendance,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Date bar
                Container(
                  color: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isToday
                                ? const Color(0xFF7BA5E8).withOpacity(0.1)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isToday
                                  ? const Color(0xFF7BA5E8)
                                  : Colors.grey[300]!,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: isToday
                                    ? const Color(0xFF7BA5E8)
                                    : Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isToday
                                    ? 'Today, ${DateFormat('dd MMM').format(_selectedDate)}'
                                    : DateFormat('dd MMM yyyy, EEEE')
                                        .format(_selectedDate),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isToday
                                      ? const Color(0xFF7BA5E8)
                                      : Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.arrow_drop_down,
                                  color: Colors.grey[600]),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (_hasExistingRecord && !_isHoliday)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Saved ✓',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Holiday toggle
                Container(
                  color: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.beach_access,
                          color: _isHoliday ? Colors.orange : Colors.grey,
                          size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Mark as Holiday',
                        style: TextStyle(
                          color:
                              _isHoliday ? Colors.orange : Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Switch(
                        value: _isHoliday,
                        activeColor: Colors.orange,
                        onChanged: (val) => setState(() => _isHoliday = val),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Summary bar
                if (!_isHoliday)
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        _buildCountChip(
                            'Present', totalPresent, Colors.green),
                        const SizedBox(width: 12),
                        _buildCountChip('Absent', totalAbsent, Colors.red),
                        const SizedBox(width: 12),
                        if (totalUnmarked > 0)
                          _buildCountChip(
                              'Unmarked', totalUnmarked, Colors.grey),
                        if (totalUnmarked > 0)
                          const SizedBox(width: 12),
                        _buildCountChip(
                            'Total', _students.length, Colors.blue),
                      ],
                    ),
                  ),

                if (!_isHoliday) const Divider(height: 1),

                // Student list
                if (_isHoliday)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.beach_access,
                              size: 80, color: Colors.orange),
                          const SizedBox(height: 16),
                          const Text(
                            'Holiday',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            DateFormat('dd MMM yyyy, EEEE')
                                .format(_selectedDate),
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_students.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_off_rounded,
                              size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          const Text(
                            'No students found',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Add students from the Admin panel first.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      physics: const BouncingScrollPhysics(),
                      itemCount: _students.length,
                      itemBuilder: (context, index) {
                        final student = _students[index];
                        final status = _attendance[student.enrollmentNumber]; // null=unmarked, true=present, false=absent

                        // Determine colors based on status
                        final Color borderColor;
                        final Color badgeColor;
                        if (status == null) {
                          borderColor = Colors.grey.withOpacity(0.3);
                          badgeColor = Colors.grey;
                        } else if (status) {
                          borderColor = Colors.green.withOpacity(0.3);
                          badgeColor = Colors.green;
                        } else {
                          borderColor = Colors.red.withOpacity(0.3);
                          badgeColor = Colors.red;
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: borderColor,
                              width: 1.5,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 2),
                            leading: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: badgeColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: badgeColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                            onTap: () => _showStudentDetails(student, status),
                            title: Text(
                              student.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              student.enrollmentNumber,
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey[600]),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Present button
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _attendance[student.enrollmentNumber] = true;
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 44,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: status == true
                                          ? Colors.green
                                          : Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.green.withOpacity(0.4),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '✓ P',
                                        style: TextStyle(
                                          color: status == true
                                              ? Colors.white
                                              : Colors.green,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // Absent button
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _attendance[student.enrollmentNumber] = false;
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 44,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: status == false
                                          ? Colors.red
                                          : Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.red.withOpacity(0.4),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '✗ A',
                                        style: TextStyle(
                                          color: status == false
                                              ? Colors.white
                                              : Colors.red,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                // Save button
                Container(
                  color: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveAttendance,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : Icon(_isHoliday
                                ? Icons.beach_access
                                : Icons.save_rounded),
                        label: Text(
                          _isHoliday
                              ? 'Mark Holiday'
                              : _hasExistingRecord
                                  ? 'Update Attendance'
                                  : 'Save Attendance',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isHoliday
                              ? Colors.orange
                              : const Color(0xFF7BA5E8),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCountChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _showStudentDetails(Student student, bool? currentStatus) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _StudentDetailSheet(
        student: student,
        subjectId: widget.subjectId,
        subjectName: widget.subjectName,
        semester: widget.semester,
        division: widget.division,
        batch: widget.batch,
        facultyId: widget.facultyId,
      ),
    );
  }
}

class _StudentDetailSheet extends StatefulWidget {
  final Student student;
  final String subjectId;
  final String subjectName;
  final String semester;
  final String division;
  final String batch;
  final String facultyId;

  const _StudentDetailSheet({
    required this.student,
    required this.subjectId,
    required this.subjectName,
    required this.semester,
    required this.division,
    required this.batch,
    required this.facultyId,
  });

  @override
  State<_StudentDetailSheet> createState() => _StudentDetailSheetState();
}

class _StudentDetailSheetState extends State<_StudentDetailSheet> {
  bool _isLoading = true;
  Map<String, dynamic>? _stats;
  String? _studentUid;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // 1. Get student stats
      final stats = await AttendanceService.getStudentAttendanceStats(
        widget.student.enrollmentNumber,
        widget.semester,
        widget.division,
        widget.batch,
      );

      // 2. Try to find the user UID for this student (to send warnings)
      // We normalize the search to be more robust
      final enrolTrimmed = widget.student.enrollmentNumber.trim();
      
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('enrollmentNumber', isEqualTo: enrolTrimmed)
          .limit(1)
          .get();

      if (mounted) {
        setState(() {
          _stats = stats;
          if (userQuery.docs.isNotEmpty) {
            _studentUid = userQuery.docs.first.id;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendWarning() async {
    if (_studentUid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot send warning: Student has not linked their account.')),
      );
      return;
    }

    try {
      // Get faculty name
      final facultyProfile = await DatabaseService.getUserProfile();
      final facultyName = facultyProfile?.email.split('@').first.toUpperCase() ?? 'Faculty';

      await DatabaseService.sendWarning(
        _studentUid!,
        facultyName,
        'Please attend ${widget.subjectName} lectures regularly. Your attendance is low.',
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Warning sent to student!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 20, left: 24, right: 24, bottom: 40),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          Row(
            children: [
              CircleAvatar(radius: 30, backgroundColor: Colors.blue.withOpacity(0.1), child: const Icon(Icons.person, size: 30, color: Colors.blue)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.student.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(widget.student.enrollmentNumber, style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          if (_isLoading)
            const CircularProgressIndicator()
          else ...[
            _buildStatRow('Current Subject (${widget.subjectName})', _stats?['subjectStats']?[widget.subjectId]?['present'] ?? 0, _stats?['subjectStats']?[widget.subjectId]?['total'] ?? 0),
            const SizedBox(height: 16),
            _buildStatRow('Overall Attendance', _stats?['totalPresent'] ?? 0, _stats?['totalLectures'] ?? 0),
            const SizedBox(height: 32),
            if (_studentUid != null)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _sendWarning,
                  icon: const Icon(Icons.notification_important_rounded),
                  label: const Text('Warn: Attend Regular Lectures'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              )
            else
              Text('Student has not set up their profile yet.', style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }

  Widget _buildStatRow(String title, int present, int total) {
    final double perc = total > 0 ? (present / total) * 100 : 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text('${perc.toStringAsFixed(1)}%', style: TextStyle(fontWeight: FontWeight.bold, color: perc >= 75 ? Colors.green : Colors.red)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: total > 0 ? present / total : 0,
            minHeight: 8,
            backgroundColor: Colors.grey[100],
            color: perc >= 75 ? Colors.green : Colors.red,
          ),
        ),
        const SizedBox(height: 4),
        Text('$present present out of $total lectures', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      ],
    );
  }
}
