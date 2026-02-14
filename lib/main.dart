import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart'; // Add this import
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/splash_screen.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'utils/theme.dart';
import 'screens/onboarding_screen.dart';
import 'screens/today_schedule_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('DEBUG: App starting...');

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize services
  print('DEBUG: Initializing Firebase...');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('DEBUG: Firebase initialized.');
  
  // Initialize Notification Service
  print('DEBUG: Initializing Notifications...');
  await NotificationService().initialize();
  print('DEBUG: Notifications initialized.');

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

  // Determine initial screen based on auth status and onboarding
  Widget _getInitialScreen() {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final user = snapshot.data;
        
        // If no user is logged in, show Auth Screen (Student/Faculty tabs)
        if (user == null) {
          return const LoginScreen();
        }

        // If user is logged in, show Today's Schedule
        return const TodayScheduleScreen();
      },
    );
  }
}
