import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'utils/theme.dart';
import 'screens/today_schedule_screen.dart';
import 'screens/weekly_setup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize services
  await DatabaseService.initialize();
  await NotificationService().initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Timecloud',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme.copyWith(
        scaffoldBackgroundColor: Colors.white,
      ),
      home: _getInitialScreen(),
    );
  }

  // Determine initial screen based on whether user has set up timetable
  Widget _getInitialScreen() {
    final hasSubjects = DatabaseService.hasSubjects();
    return hasSubjects ? const TodayScheduleScreen() : const WeeklySetupScreen();
  }
}
