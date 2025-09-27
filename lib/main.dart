import 'dart:async'; // Added for Stopwatch
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:myapp/auth_service.dart';
import 'package:myapp/dashboard_page.dart';
import 'package:myapp/therapy_provider.dart';
import 'package:myapp/personal_exercise_provider.dart';
import 'package:myapp/role_selection_page.dart';
import 'package:myapp/doctor_home_page.dart';
import 'firebase_options.dart';

// Imports for local notifications
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _initializeNotifications() async {
  tz.initializeTimeZones();
  try {
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
  } catch (e) {
    print('Error setting local location: $e');
    tz.setLocalLocation(tz.UTC);
  }
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
    macOS: initializationSettingsDarwin,
  );
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse:
        (NotificationResponse notificationResponse) async {
      print('Notification Tapped: ${notificationResponse.payload}');
    },
    onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
  );
  final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
  await androidImplementation?.requestNotificationsPermission();
  await androidImplementation?.requestExactAlarmsPermission();
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  print('Notification Tapped in Background/Terminated: ${notificationResponse.payload}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('[main] Initializing Firebase...');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('[main] Firebase initialized.');
  await _initializeNotifications();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => TherapyProvider()),
        ChangeNotifierProvider(create: (context) => PersonalExerciseProvider()),
      ],
      child: const PanchakarmaPulseApp(),
    ),
  );
}

class PanchakarmaPulseApp extends StatelessWidget {
  const PanchakarmaPulseApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Panchakarma Pulse',
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'YourPreferredFont',
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});
  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  Future<String?> _getUserRoleFromFirestore() async {
    final functionStopwatch = Stopwatch()..start(); // Stopwatch for the whole function
    print('[${DateTime.now()}] _AuthWrapperState: _getUserRoleFromFirestore START');

    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      print('[${DateTime.now()}] _AuthWrapperState: No current user for Firestore role check.');
      functionStopwatch.stop();
      print('[${DateTime.now()}] _AuthWrapperState: _getUserRoleFromFirestore END (no user) - Took ${functionStopwatch.elapsedMilliseconds}ms');
      return null;
    }

    print('[${DateTime.now()}] _AuthWrapperState: Checking Firestore for role of user: ${currentUser.uid}');
    String? roleResult;
    final firestoreCallStopwatch = Stopwatch(); // Stopwatch for the Firestore call only

    try {
      print('[${DateTime.now()}] _AuthWrapperState: BEFORE Firestore get() call.');
      firestoreCallStopwatch.start();
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      firestoreCallStopwatch.stop();
      print('[${DateTime.now()}] _AuthWrapperState: AFTER Firestore get() call. Exists: ${userDoc.exists}. Took ${firestoreCallStopwatch.elapsedMilliseconds}ms');

      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data() as Map<String, dynamic>;
        roleResult = data['role'] as String?;
        print('[${DateTime.now()}] _AuthWrapperState: Role from Firestore: $roleResult');
      } else {
        print('[${DateTime.now()}] _AuthWrapperState: User document does not exist in Firestore or no role field.');
        roleResult = null;
      }
    } catch (e, s) {
      firestoreCallStopwatch.stop(); // Stop if it was running and an error occurred
      print('[${DateTime.now()}] _AuthWrapperState: Error fetching role from Firestore: $e');
      print('[${DateTime.now()}] _AuthWrapperState: Stacktrace: $s');
      print('[${DateTime.now()}] _AuthWrapperState: Firestore call (if started) took ${firestoreCallStopwatch.elapsedMilliseconds}ms before error.');
      roleResult = null;
    }
    functionStopwatch.stop();
    print('[${DateTime.now()}] _AuthWrapperState: _getUserRoleFromFirestore END - Result: $roleResult. Total took ${functionStopwatch.elapsedMilliseconds}ms');
    return roleResult;
  }

  @override
  Widget build(BuildContext context) {
    print('[${DateTime.now()}] _AuthWrapperState: Build method called.');
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        print('[${DateTime.now()}] _AuthWrapperState: Auth StreamBuilder - ConnectionState: ${authSnapshot.connectionState}, HasData: ${authSnapshot.hasData}, HasError: ${authSnapshot.hasError}, Error: ${authSnapshot.error}');
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          print('[${DateTime.now()}] _AuthWrapperState: Auth state WAITING (showing loading indicator).');
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (authSnapshot.hasData && authSnapshot.data != null) {
          print('[${DateTime.now()}] _AuthWrapperState: Auth state HAS DATA. User logged in: ${authSnapshot.data!.uid}. Now calling FutureBuilder for role.');
          return FutureBuilder<String?>(
            future: _getUserRoleFromFirestore(),
            builder: (context, roleSnapshot) {
              print('[${DateTime.now()}] _AuthWrapperState: Role FutureBuilder - ConnectionState: ${roleSnapshot.connectionState}, HasData: ${roleSnapshot.hasData}, HasError: ${roleSnapshot.hasError}, Error: ${roleSnapshot.error}, Data: ${roleSnapshot.data}');
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                print('[${DateTime.now()}] _AuthWrapperState: Role future WAITING for Firestore (showing loading indicator).');
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              if (roleSnapshot.hasError) {
                print('[${DateTime.now()}] _AuthWrapperState: Role future HAS ERROR: ${roleSnapshot.error}. Navigating to RoleSelectionPage as fallback.');
                return const RoleSelectionPage(); 
              }

              final role = roleSnapshot.data;
              print('[${DateTime.now()}] _AuthWrapperState: Role future HAS DATA. Role: $role');

              if (role == null) {
                print('[${DateTime.now()}] _AuthWrapperState: No role found in Firestore, navigating to RoleSelectionPage.');
                return const RoleSelectionPage();
              } else if (role == 'user') {
                print('[${DateTime.now()}] _AuthWrapperState: Role is \'user\', navigating to DashboardPage.');
                return const DashboardPage();
              } else if (role == 'doctor') {
                print('[${DateTime.now()}] _AuthWrapperState: Role is \'doctor\', navigating to DoctorHomePage.');
                return const DoctorHomePage();
              } else {
                print('[${DateTime.now()}] _AuthWrapperState: Unknown role \'$role\', navigating to RoleSelectionPage as fallback.');
                return const RoleSelectionPage();
              }
            },
          );
        }
        print('[${DateTime.now()}] _AuthWrapperState: Auth state NO DATA. User not logged in. Navigating to LoginPage.');
        return const LoginPage();
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Icon(
                  Icons.spa,
                  size: 80,
                  color: Colors.green[700],
                ),
                const SizedBox(height: 16),
                Text(
                  'Panchakarma Pulse',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Next-Gen Solutions for Ayurvedic Therapy Management',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 60),
                OutlinedButton(
                  onPressed: () async {
                    User? user = await _authService.signInWithGoogle();
                    if (user == null && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Google Sign-In failed or cancelled.')),
                      );
                    } 
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14.0),
                    side: BorderSide(color: Colors.grey[400]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: Text(
                    'Sign in with Google',
                    style: TextStyle(color: Colors.grey[800], fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
