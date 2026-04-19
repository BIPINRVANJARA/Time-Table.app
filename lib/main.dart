import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart'; // Add this import
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart'; // App Check
import 'firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/splash_screen.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'utils/theme.dart';
import 'screens/onboarding_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/today_schedule_screen.dart';
import 'screens/login_screen.dart';
import 'screens/faculty/faculty_dashboard_screen.dart';
import 'services/faculty_service.dart';
import 'models/faculty.dart';

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

  // Initialize Firebase App Check
  print('DEBUG: Initializing App Check...');
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
    appleProvider: AppleProvider.deviceCheck,
  );
  print('DEBUG: App Check initialized.');
  
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

  // Determine initial screen based on auth status and role
  Widget _getInitialScreen() {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final user = snapshot.data;

        // NEW: Check local faculty session (even if FirebaseAuth is null)
        return FutureBuilder<String?>(
          future: FacultyService.getLocalSessionId(),
          builder: (context, sessionSnapshot) {
            if (sessionSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            final localFacultyId = sessionSnapshot.data;

            // 1. If we have a local faculty ID, show Dashboard (Self-healing login)
            if (localFacultyId != null) {
              return FutureBuilder<Faculty?>(
                future: FacultyService.getFacultyByFacultyId(localFacultyId),
                builder: (context, facultyDoc) {
                  if (facultyDoc.connectionState == ConnectionState.waiting) {
                    return const Scaffold(body: Center(child: CircularProgressIndicator()));
                  }

                  if (facultyDoc.hasData && facultyDoc.data != null) {
                    final f = facultyDoc.data!;
                    return FacultyDashboardScreen(
                      facultyId: f.facultyId,
                      facultyName: f.facultyName,
                      role: f.role,
                      department: f.department,
                    );
                  }
                  
                  // If doc missing but session exists, clear session and go to login
                  FacultyService.clearLocalSession();
                  return const LoginScreen();
                },
              );
            }

            // 2. If no local faculty session, check Firebase Auth for Admin/Student
            if (user == null) {
              return const LoginScreen();
            }

            // 3. Admin/Student logic (Firestore users collection)
            return const TodayScheduleScreen();
          },
        );
      },
    );
  }
}
