import 'package:esavior_doctor/service/appointment_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

// Global notification plugin instance
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

// Global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // PHASE 1: Initialize basic services (BEFORE LOGIN)
    print('🚀 Phase 1: Initializing basic services...');
    await OptimizedAppointmentService().initializeBasicServices();
    print('✅ Phase 1: Basic services are ready');
  } catch (e) {
    print('❌ Phase 1 Error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Doctor App',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with WidgetsBindingObserver {
  final _storage = const FlutterSecureStorage();
  String _currentStatus = 'Initializing...';
  bool _isBasicServicesReady = false;
  bool _isPermissionsChecked = false;
  bool _isUserServicesReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupNotificationHandlers();
    _initializeAndCheckLogin();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      // App returned to foreground - check for any missed notifications
      _checkMissedNotifications();
    }
  }

  void _setupNotificationHandlers() {
    // Handle notification taps when app is running
    flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleNotificationTap(response);
      },
    );
  }

  void _handleNotificationTap(NotificationResponse response) {
    print('👆 Local notification tapped: ${response.payload}');
    _navigateToAppointments();
  }

  void _navigateToAppointments() {
    // Implementation depends on your app structure
    print('🔄 Navigating to appointments screen');
  }

  Future<void> _checkMissedNotifications() async {
    try {
      final pendingNotifications =
      await flutterLocalNotificationsPlugin.pendingNotificationRequests();
      print('📊 Pending notifications: ${pendingNotifications.length}');
    } catch (e) {
      print('❌ Error checking missed notifications: $e');
    }
  }

  Future<void> _initializeAndCheckLogin() async {
    try {
      setState(() {
        _currentStatus = 'Preparing basic services...';
      });

      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _isBasicServicesReady = true;
        _currentStatus = 'Checking access permissions...';
      });

      await _checkLogin();
    } catch (e) {
      print('❌ Error during initialization: $e');
      _showErrorAndProceed(e.toString());
    }
  }

  Future<void> _checkLogin() async {
    try {
      final doctorIdString = await _storage.read(key: 'doctor_id');
      if (doctorIdString != null) {
        final doctorId = int.tryParse(doctorIdString);
        if (doctorId != null) {
          // Already logged in - Initialize PHASE 2 and go to HomeScreen
          setState(() {
            _currentStatus = 'Initializing advanced services...';
          });

          // PHASE 2: Initialize services requiring doctor_id (AFTER LOGIN)
          await _initializeUserSpecificServices(doctorId);

          setState(() {
            _isUserServicesReady = true;
            _currentStatus = 'Initialization complete...';
          });

          await Future.delayed(const Duration(milliseconds: 500));

          if (mounted) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    HomeScreen(doctorId: doctorId),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
                transitionDuration: const Duration(milliseconds: 500),
              ),
            );
          }
          return;
        }
      }

      // Not logged in - navigate to LoginScreen
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    } catch (e) {
      print('❌ Error checking login: $e');
      _showErrorAndProceed(e.toString());
    }
  }

  Future<void> _initializeUserSpecificServices(int doctorId) async {
    try {
      print('🚀 Phase 2: Initializing user services for doctor $doctorId...');
      await OptimizedAppointmentService().initializeUserServices(doctorId);
      print('✅ Phase 2: User services are ready');
    } catch (e) {
      print('❌ Phase 2 Error: $e');
    }
  }

  void _showErrorAndProceed(String error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Initialization error: $error'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2196F3),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Icon with animation
                TweenAnimationBuilder<double>(
                  duration: const Duration(seconds: 2),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 0.8 + (0.2 * value),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.local_hospital,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),

                // App Title
                const Text(
                  'Doctor App',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  'Smart medical appointment management',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Loading indicator
                const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
                const SizedBox(height: 24),

                // Status text with animation
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _currentStatus,
                    key: ValueKey(_currentStatus),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
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
