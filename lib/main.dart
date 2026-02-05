import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'utils/theme.dart';
import 'screens/onboarding_screen.dart';
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
      title: 'Timestunner',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme.copyWith(
        scaffoldBackgroundColor: Colors.white,
      ),
      home: _getInitialScreen(),
    );
  }

  // Determine initial screen based on onboarding status and timetable setup
  Widget _getInitialScreen() {
    return FutureBuilder<bool>(
      future: _checkOnboardingStatus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        final onboardingComplete = snapshot.data ?? false;
        
        if (!onboardingComplete) {
          return const OnboardingScreen();
        }
        
        final hasSubjects = DatabaseService.hasSubjects();
        return hasSubjects ? const TodayScheduleScreen() : const WeeklySetupScreen();
      },
    );
  }
  
  Future<bool> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_complete') ?? false;
  }
}
