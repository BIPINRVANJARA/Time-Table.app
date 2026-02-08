import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/subject.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import '../utils/theme.dart';
import '../widgets/subject_card.dart';
import '../widgets/date_selector.dart';
import '../services/notification_service.dart';
import 'notification_debug_screen.dart';
import 'admin/admin_dashboard_screen.dart';
import 'academic_setup_screen.dart';
import 'login_screen.dart';

class TodayScheduleScreen extends StatefulWidget {
  const TodayScheduleScreen({super.key});

  @override
  State<TodayScheduleScreen> createState() => _TodayScheduleScreenState();
}

class _TodayScheduleScreenState extends State<TodayScheduleScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserModel?>(
      stream: DatabaseService.streamUserProfile(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final userProfile = userSnapshot.data;

        if (userProfile == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Text('Profile not found. Please log in again.'),
                   const SizedBox(height: 16),
                   ElevatedButton(
                     onPressed: () {
                        // Restart app flow
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                     },
                     child: const Text('Log In'),
                   ),
                ],
              ),
            ),
          );
        }

        // Check if academic setup is needed (only for students)
        final bool needsSetup = userProfile.role.toLowerCase() != 'admin' && userProfile.branch.isEmpty;

        final dayOfWeek = _selectedDate.weekday;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Today's Schedule,",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  DateFormat('MMMM, d').format(_selectedDate),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            actions: [
              if (userProfile.role.toLowerCase() == 'admin')
                IconButton(
                  icon: const Icon(Icons.admin_panel_settings, color: Color(0xFF7BA5E8)),
                  tooltip: 'Admin Panel',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
                    );
                  },
                ),
              IconButton(
                icon: const Icon(Icons.person, color: Colors.black54),
                tooltip: 'Profile',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => AcademicSetupScreen(userModel: userProfile),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.black54),
                tooltip: 'Logout',
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.bug_report),
                tooltip: 'Debug Notifications',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const NotificationDebugScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // Horizontal date selector
              Container(
                color: Colors.white,
                child: DateSelector(
                  selectedDate: _selectedDate,
                  onDateSelected: (date) {
                    setState(() {
                      _selectedDate = date;
                    });
                  },
                ),
              ),

              // Subject list (Stream from Firestore)
              Expanded(
                child: needsSetup 
                  ? _buildSetupPrompt()
                  : StreamBuilder<List<Subject>>(
                      stream: DatabaseService.streamTimetable(
                        userProfile.branch,
                        userProfile.semester,
                        userProfile.division,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}'));
                        }

                        // Filter by day locally for now (can be optimized query-side)
                        final allSubjects = snapshot.data ?? [];
                        
                        // Reschedule notifications (Side Effect - consider moving to a better place if performance issues arise)
                        // Note: rescheduling cancels all and re-adds, so we should be careful.
                        // Ideally checking if data changed. But for now, we do it to ensure sync.
                        // To avoid loop, we can wrap in Microtask or just execute.
                        // Better approach: Only do this once per app launch? No, schedule changes.
                        // We will execute this. NotificationService.rescheduleAllNotifications handles bulk ops.
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                           // We use a throttle or just rely on the fact that streams don't emit continuously.
                           // Actually, constantly cancelling/scheduling on every build of this widget (if parent rebuilds) is bad.
                           // But this is inside StreamBuilder, so it only runs when stream emits new data. Which is rare (admin updates).
                           // So it's safe.
                           NotificationService().rescheduleAllNotifications(allSubjects, userProfile.batch);
                        });

                        final subjects = allSubjects
                            .where((s) => s.dayOfWeek == dayOfWeek)
                            .where((s) {
                              // Filter by batch if it's a specific batch subject (e.g. Lab)
                              // If subject has a batch, it must match user's batch.
                              // If subject batch is null/empty, it's for everyone.
                              if (s.batch != null && s.batch!.isNotEmpty) {
                                return s.batch == userProfile.batch;
                              }
                              return true;
                            })
                            .toList();
                        
                        // Sort by time
                        subjects.sort((a, b) => a.startInMinutes.compareTo(b.startInMinutes));

                        if (subjects.isEmpty) {
                          return _buildEmptyState(dayOfWeek);
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          physics: const BouncingScrollPhysics(),
                          itemCount: subjects.length,
                          itemBuilder: (context, index) {
                            final subject = subjects[index];
                            return SubjectCard(
                              key: ValueKey(subject.id),
                              subject: subject,
                            );
                          },
                        );
                      },
                    ),
              ),
            ],
          ),
        );
      },
    );
  }


  Widget _buildEmptyState(int dayOfWeek) {
    final dayName = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][dayOfWeek];
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available,
            size: 80,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            dayOfWeek == 7 ? 'It\'s Sunday! 🎉' : 'No classes today! 🎉',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No classes scheduled for $dayName',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetupPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 24),
            const Text(
              'Complete Your Profile',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Please select your branch and semester to see your timetable.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AcademicSetupScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7BA5E8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('Setup Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
