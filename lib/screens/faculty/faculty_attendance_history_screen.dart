import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/attendance_record.dart';
import '../../services/attendance_service.dart';
import 'attendance_screen.dart';

class FacultyAttendanceHistoryScreen extends StatefulWidget {
  final String facultyId;

  const FacultyAttendanceHistoryScreen({super.key, required this.facultyId});

  @override
  State<FacultyAttendanceHistoryScreen> createState() => _FacultyAttendanceHistoryScreenState();
}

class _FacultyAttendanceHistoryScreenState extends State<FacultyAttendanceHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedMonth = DateFormat('MMMM yyyy').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        title: const Text('Attendance Management', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF3B82F6),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF3B82F6),
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'All Records'),
          ],
        ),
      ),
      body: StreamBuilder<List<AttendanceRecord>>(
        stream: AttendanceService.streamFacultyAttendanceRecords(widget.facultyId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final error = snapshot.error.toString();
            if (error.contains('requires an index')) {
              return _buildIndexErrorState(error);
            }
            return Center(child: Text('Error: $error', style: const TextStyle(color: Colors.red)));
          }

          final allRecords = snapshot.data ?? [];
          if (allRecords.isEmpty) {
            return _buildEmptyState();
          }

          final stats = AttendanceService.aggregateDashboardStats(allRecords);

          return TabBarView(
            controller: _tabController,
            children: [
              _buildDashboardView(stats, allRecords),
              _buildHistoryListView(allRecords),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDashboardView(Map<String, dynamic> stats, List<AttendanceRecord> allRecords) {
    final Map<String, dynamic> subjectStats = stats['subjectStats'];
    final List<Map<String, dynamic>> atRisk = List<Map<String, dynamic>>.from(stats['atRiskStudents']);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      children: [
        // Summary Cards
        Row(
          children: [
            _buildStatCard('Classes', stats['totalClasses'].toString(), Icons.class_rounded, const Color(0xFF3B82F6)),
            const SizedBox(width: 12),
            _buildStatCard('Low Attendance', stats['atRiskCount'].toString(), Icons.warning_amber_rounded, const Color(0xFFEF4444)),
          ],
        ),
        const SizedBox(height: 24),

        // At Risk Students Section
        if (atRisk.isNotEmpty) ...[
          _buildSectionHeader('Students at Risk (<75%)', Icons.trending_down_rounded, () {
             // Future: show full list
          }),
          const SizedBox(height: 12),
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: atRisk.length,
              itemBuilder: (context, index) {
                final student = atRisk[index];
                return _buildAtRiskCard(student);
              },
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Subject Management Section
        _buildSectionHeader('Subject Management', Icons.analytics_rounded, null),
        const SizedBox(height: 12),
        ...subjectStats.values.map((s) => _buildSubjectManagementCard(s)).toList(),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, VoidCallback? onTap) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
        const Spacer(),
        if (onTap != null)
          TextButton(onPressed: onTap, child: const Text('View All', style: TextStyle(fontSize: 13))),
      ],
    );
  }

  Widget _buildAtRiskCard(Map<String, dynamic> student) {
    final double pct = (student['percentage'] as double) * 100;
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.withOpacity(0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            student['enrollment'],
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '${student['present']}/${student['total']} Classes',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: student['percentage'] as double,
                  backgroundColor: Colors.red.withOpacity(0.1),
                  color: Colors.red,
                  minHeight: 4,
                ),
              ),
              const SizedBox(width: 8),
              Text('${pct.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectManagementCard(Map<String, dynamic> s) {
    final List<AttendanceRecord> lectureRecords = List<AttendanceRecord>.from(s['lectureRecords']);
    final Map<String, List<AttendanceRecord>> labBatches = Map<String, List<AttendanceRecord>>.from(s['labBatches']);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFF3B82F6).withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.auto_stories_rounded, color: Color(0xFF3B82F6)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF1E293B))),
                      Text('Sem ${s['semester']} | Div ${s['division']}', style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          
          // Lecture Row
          if (lectureRecords.isNotEmpty)
            _buildNestedSubjectRow('Lectures', lectureRecords.length, lectureRecords),
            
          // Lab Rows (one per batch)
          ...labBatches.entries.map((entry) => 
            _buildNestedSubjectRow('Lab Batch ${entry.key}', entry.value.length, entry.value)
          ).toList(),
          
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildNestedSubjectRow(String label, int count, List<AttendanceRecord> records) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 8, color: Color(0xFF3B82F6)),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF475569))),
          const Spacer(),
          Text('$count Records', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          const SizedBox(width: 12),
          TextButton(
            onPressed: () {
              // Direct navigation to history list for this specific subset
               _tabController.animateTo(1);
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: const Color(0xFFF1F5F9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text('Manage', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6))),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryListView(List<AttendanceRecord> allRecords) {
    // Group records by class (Subject + Semester + Division)
    final Map<String, Map<String, dynamic>> subjectMap = {};
    for (var record in allRecords) {
      // Aggressive Normalization
      String cleanName = record.subjectName
          .replaceAll(RegExp(r'B[0-9]-'), '')
          .replaceAll(RegExp(r'\([^)]*\)'), '')
          .replaceAll(RegExp(r'-[0-9]{3}[A-Z]?'), '')
          .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
          .trim()
          .toUpperCase();
          
      if (cleanName.isEmpty) cleanName = record.subjectName.toUpperCase();
      
      final key = '${record.semester}_${record.division}_$cleanName';
      if (!subjectMap.containsKey(key)) {
        subjectMap[key] = {
          'name': record.subjectName, // Initial name
          'semester': record.semester,
          'division': record.division,
          'lectureRecords': <AttendanceRecord>[],
          'labGroups': <String, List<AttendanceRecord>>{},
        };
      }
      
      // Keep the "Cleanest" (Shortest) name for the folder label
      if (record.subjectName.length < (subjectMap[key]!['name'] as String).length) {
        subjectMap[key]!['name'] = record.subjectName;
      }
      
      final isLec = record.batch.isEmpty || record.batch == 'All' || record.batch == 'ALL';
      if (isLec) {
        (subjectMap[key]!['lectureRecords'] as List<AttendanceRecord>).add(record);
      } else {
        final labs = subjectMap[key]!['labGroups'] as Map<String, List<AttendanceRecord>>;
        if (!labs.containsKey(record.batch)) labs[record.batch] = [];
        labs[record.batch]!.add(record);
      }
    }

    final subjects = subjectMap.values.toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: subjects.length,
      itemBuilder: (context, index) {
        final s = subjects[index];
        return _buildSubjectExpansionTileV2(s);
      },
    );
  }

  Widget _buildSubjectExpansionTileV2(Map<String, dynamic> s) {
    final lectures = s['lectureRecords'] as List<AttendanceRecord>;
    final labs = s['labGroups'] as Map<String, List<AttendanceRecord>>;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 4)]),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: const Icon(Icons.folder_shared_rounded, color: Color(0xFF94A3B8)),
        title: Text(s['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text('Sem ${s['semester']} | Div ${s['division']}', style: const TextStyle(fontSize: 13)),
        children: [
          if (lectures.isNotEmpty)
            _buildInternalFolder('Lectures', lectures),
          ...labs.entries.map((entry) => _buildInternalFolder('Lab ${entry.key}', entry.value)).toList(),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildInternalFolder(String title, List<AttendanceRecord> records) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF3B82F6))),
        ),
        leading: const Padding(
          padding: EdgeInsets.only(left: 12),
          child: Icon(Icons.keyboard_arrow_right_rounded, color: Color(0xFF3B82F6)),
        ),
        children: records.map((record) => ListTile(
          dense: true,
          contentPadding: const EdgeInsets.only(left: 60, right: 20),
          title: Text(DateFormat('dd MMM yyyy').format(DateTime.parse(record.date)), style: const TextStyle(fontWeight: FontWeight.w500)),
          trailing: Text('${record.totalPresent}P', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AttendanceScreen(
            subjectId: record.subjectId,
            subjectName: record.subjectName,
            subjectType: (record.batch.isEmpty || record.batch == 'All' || record.batch == 'ALL') ? 'lecture' : 'lab',
            semester: record.semester,
            division: record.division,
            batch: record.batch,
            facultyId: widget.facultyId,
            initialDate: DateTime.parse(record.date),
          ))),
        )).toList(),
      ),
    );
  }

  // --- Reused Helper Methods (Export, Error State, Empty State) ---
  
  Future<void> _exportCSV(AttendanceRecord info) async {
    final range = await showDateRangePicker(context: context, firstDate: DateTime(2024), lastDate: DateTime.now());
    if (range == null) return;
    try {
      final csv = await AttendanceService.exportAttendanceCSV(
        (info.batch.isEmpty || info.batch == 'All' || info.batch == 'ALL') ? 'lecture' : 'lab',
        info.semester, info.division, info.batch, info.subjectId, info.subjectName,
        startDate: DateFormat('yyyy-MM-dd').format(range.start),
        endDate: DateFormat('yyyy-MM-dd').format(range.end),
      );
      if (csv == 'No attendance records found.') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No records found.')));
        return;
      }
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/${info.subjectName.replaceAll(' ', '_')}_Attendance.csv');
      await file.writeAsString(csv);
      await Share.shareXFiles([XFile(file.path)], subject: 'Attendance Report');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  Widget _buildIndexErrorState(String error) {
    final url = RegExp(r'https://[^\s]+').firstMatch(error)?.group(0);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.settings_input_component_rounded, size: 60, color: Colors.orange),
            const SizedBox(height: 20),
            const Text('Database Index Required', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('Your history stats are ready! Click the button below to authorize the view in your browser.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            if (url != null)
              ElevatedButton.icon(
                onPressed: () { Clipboard.setData(ClipboardData(text: url)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link copied!'))); },
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Copy Index Link'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          const Text('No Attendance Data Yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          const Text('Mark some classes to see your analytics here.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
