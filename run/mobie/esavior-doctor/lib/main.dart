import 'package:esavior_doctor/service/appointment_service.dart';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'screens/login_screen.dart';
import 'screens/home_screen.dart';


// Global notification plugin instance
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // PHASE 1: Khởi tạo các service cơ bản (TRƯỚC LOGIN)
    print('🚀 Phase 1: Khởi tạo services cơ bản...');
    await AppointmentService().initializeBasicServices();
    print('✅ Phase 1: Services cơ bản đã sẵn sàng');

  } catch (e) {
    print('❌ Lỗi Phase 1: $e');
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
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
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

class _SplashScreenState extends State<SplashScreen> {
  final _storage = const FlutterSecureStorage();
  String _currentStatus = 'Đang khởi tạo...';
  bool _isBasicServicesReady = false;

  @override
  void initState() {
    super.initState();
    _initializeAndCheckLogin();
  }

  Future<void> _initializeAndCheckLogin() async {
    try {
      // Đợi Phase 1 hoàn tất
      setState(() {
        _currentStatus = 'Đang chuẩn bị dịch vụ cơ bản...';
      });

      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _isBasicServicesReady = true;
        _currentStatus = 'Đang kiểm tra đăng nhập...';
      });

      // Kiểm tra trạng thái đăng nhập
      await _checkLogin();

    } catch (e) {
      print('❌ Lỗi trong quá trình khởi tạo: $e');
      await _checkLogin();
    }
  }

  Future<void> _checkLogin() async {
    try {
      final doctorIdString = await _storage.read(key: 'doctor_id');
      if (doctorIdString != null) {
        final doctorId = int.tryParse(doctorIdString);
        if (doctorId != null) {
          // Đã login - Khởi tạo PHASE 2 và chuyển sang HomeScreen
          setState(() {
            _currentStatus = 'Đang khởi tạo dịch vụ nâng cao...';
          });

          // PHASE 2: Khởi tạo services cần doctor_id (SAU LOGIN)
          await _initializeUserSpecificServices(doctorId);

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => HomeScreen(doctorId: doctorId)),
            );
          }
          return;
        }
      }

      // Chưa login - chuyển sang LoginScreen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (e) {
      print('❌ Lỗi khi kiểm tra đăng nhập: $e');
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  Future<void> _initializeUserSpecificServices(int doctorId) async {
    try {
      print('🚀 Phase 2: Khởi tạo services cho user $doctorId...');
      await AppointmentService().initializeUserServices(doctorId);
      print('✅ Phase 2: User services đã sẵn sàng');
    } catch (e) {
      print('❌ Lỗi Phase 2: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2196F3),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.local_hospital,
                size: 80,
                color: Colors.white,
              ),
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
              'Quản lý lịch khám bệnh',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 48),

            // Loading indicator
            const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
            const SizedBox(height: 24),

            // Status text
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

            const SizedBox(height: 16),

            // Progress indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildProgressDot('Firebase', true),
                const SizedBox(width: 8),
                _buildProgressDot('Thông báo', _isBasicServicesReady),
                const SizedBox(width: 8),
                _buildProgressDot('Permissions', _isBasicServicesReady),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressDot(String label, bool isCompleted) {
    return Column(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isCompleted
                ? Colors.white
                : Colors.white.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isCompleted
                ? Colors.white
                : Colors.white.withOpacity(0.5),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
