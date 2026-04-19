import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/user_model.dart';
import '../../services/database_service.dart';
import '../../services/attendance_service.dart';
import '../academic_setup_screen.dart';
import 'package:intl/intl.dart';

class StudentProfileScreen extends StatefulWidget {
  final UserModel userModel;

  const StudentProfileScreen({super.key, required this.userModel});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _attendanceStats;

  @override
  void initState() {
    super.initState();
    _loadAttendanceData();
  }

  Future<void> _loadAttendanceData() async {
    if (widget.userModel.enrollmentNumber == null || widget.userModel.enrollmentNumber!.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final stats = await AttendanceService.getStudentAttendanceStats(
        widget.userModel.enrollmentNumber!,
        widget.userModel.semester,
        widget.userModel.division,
        widget.userModel.batch,
      );
      if (mounted) {
        setState(() {
          _attendanceStats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
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
            SnackBar(content: Text('Error loading attendance: $e')),
          );
        }
      }
    }
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
              'Your attendance database is being prepared. To speed this up, click the button below to authorize the database index.',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Color(0xFF7BA5E8)),
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => AcademicSetupScreen(userModel: widget.userModel)),
              );
              if (result == true) {
                // Refresh data if needed
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAttendanceData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildProfileHeader(),
                    const SizedBox(height: 24),
                    _buildOverallAttendance(),
                    const SizedBox(height: 24),
                    _buildWarningsSection(),
                    const SizedBox(height: 24),
                    _buildSubjectWiseAttendance(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: const Color(0xFF7BA5E8).withOpacity(0.1),
            child: const Icon(Icons.person, size: 40, color: Color(0xFF7BA5E8)),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userModel.email.split('@').first.toUpperCase(),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.userModel.branch} | Sem ${widget.userModel.semester}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                Text(
                  'Div ${widget.userModel.division} | Batch ${widget.userModel.batch}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                if (widget.userModel.enrollmentNumber != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Enrollment: ${widget.userModel.enrollmentNumber}',
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF7BA5E8)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallAttendance() {
    final double percentage = _attendanceStats?['overallPercentage'] ?? 0.0;
    final int present = _attendanceStats?['totalPresent'] ?? 0;
    final int total = _attendanceStats?['totalLectures'] ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7BA5E8), Color(0xFF9DBEF5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: const Color(0xFF7BA5E8).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Overall Attendance',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: percentage / 100,
                  strokeWidth: 10,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatInfo('Present', '$present'),
              Container(height: 20, width: 1, color: Colors.white30, margin: const EdgeInsets.symmetric(horizontal: 20)),
              _buildStatInfo('Total', '$total'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatInfo(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
      ],
    );
  }

  Widget _buildWarningsSection() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: DatabaseService.streamWarnings(widget.userModel.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();

        final warnings = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 12),
              child: Text('Alerts from Faculty', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            ...warnings.map((w) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              w['message'],
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              'Sent by ${w['facultyName']} • ${w['timestamp'] != null ? DateFormat('dd MMM, hh:mm a').format((w['timestamp'] as dynamic).toDate()) : 'Recently'}',
                              style: TextStyle(color: Colors.grey[700], fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )).toList(),
          ],
        );
      },
    );
  }

  Widget _buildSubjectWiseAttendance() {
    final Map<String, dynamic>? subjectStatsMap = _attendanceStats?['subjectStats'];
    if (subjectStatsMap == null || subjectStatsMap.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Text('No attendance records marked yet.'),
      ));
    }

    final subjects = subjectStatsMap.entries.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text('Subject Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: subjects.length,
          itemBuilder: (context, index) {
            final entry = subjects[index];
            final stats = entry.value;
            final double perc = (stats['present'] / stats['total']) * 100;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          stats['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${perc.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: _getColorForPerc(perc),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: perc / 100,
                      backgroundColor: Colors.grey[200],
                      color: _getColorForPerc(perc),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${stats['present']} present out of ${stats['total']}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      Text(
                        perc >= 75 ? 'Criteria Met ✓' : 'Short Attend. ⚠️',
                        style: TextStyle(
                          color: perc >= 75 ? Colors.green : Colors.red,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Color _getColorForPerc(double perc) {
    if (perc >= 75) return Colors.green;
    if (perc >= 60) return Colors.orange;
    return Colors.red;
  }
}
