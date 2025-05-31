import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:workmanager/workmanager.dart';
import 'appointment_details_screen.dart'; // Import the details screen
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';


// Enum để định nghĩa các loại filter
enum FilterType { today, thisMonth, thisYear }

// Hàm xử lý thông báo đẩy khi ứng dụng ở chế độ nền
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Có thể xử lý thêm logic nếu cần, ví dụ: lưu thông báo hoặc gọi API
}

// Định nghĩa task cho Workmanager
const String fetchAppointmentsTask = 'fetchAppointmentsTask';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print('Workmanager task fetchAppointmentsTask bắt đầu vào: ${DateTime.now()}');
    try {
      await Firebase.initializeApp();
      tz.initializeTimeZones();
      final storage = FlutterSecureStorage();
      final idString = await storage.read(key: 'doctor_id');
      if (idString != null) {
        final doctorId = int.tryParse(idString);
        if (doctorId != null) {
          final url = Uri.http('10.0.2.2:8081', '/api/v1/appointments/list', {
            'doctor_id': doctorId.toString(),
          });
          final response = await http.get(url);
          print('API response status: ${response.statusCode}');
          if (response.statusCode == 200) {
            final appointments = jsonDecode(response.body);
            print('Số lượng lịch hẹn nhận được: ${appointments.length}');
            final now = tz.TZDateTime.now(tz.getLocation('Asia/Ho_Chi_Minh'));
            final todayStart = tz.TZDateTime(tz.getLocation('Asia/Ho_Chi_Minh'), now.year, now.month, now.day);
            final currentTime = DateTime.now();
            final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
            final vietnamTimeZone = tz.getLocation('Asia/Ho_Chi_Minh');

            for (var i = 0; i < appointments.length; i++) {
              final a = appointments[i];
              if (a['status'] != 'PENDING') continue;
              final medicalDay = a['medical_day'];
              if (medicalDay == null) continue;

              try {
                final parsedMedicalDay = DateTime.parse(medicalDay);
                if (parsedMedicalDay.isAtSameMomentAs(todayStart)) {
                  final slot = a['slot'];
                  const timeSlots = [8, 9, 10, 11, 13, 14, 15, 16];
                  if (slot is int && slot >= 1 && slot <= 8) {
                    final appointmentHour = timeSlots[slot - 1];
                    final appointmentTime = DateTime(
                      parsedMedicalDay.year,
                      parsedMedicalDay.month,
                      parsedMedicalDay.day,
                      appointmentHour,
                    );
                    final timeUntilAppointment = appointmentTime.difference(currentTime);
                    final patientName = a['patient'] != null && a['patient'].isNotEmpty
                        ? a['patient'][0]['patient_name'] ?? 'Bệnh nhân ID: ${a['patient_id']}'
                        : 'Bệnh nhân ID: ${a['patient_id'] ?? 'Không xác định'}';

                    // Chỉ thông báo trước 15 phút
                    if (timeUntilAppointment.inMinutes > 0 && timeUntilAppointment.inMinutes <= 20) {
                      print('Lập lịch thông báo 15p cho: $patientName, thời gian: $appointmentTime');
                      const androidPlatformChannelSpecifics = AndroidNotificationDetails(
                        'appointment_channel_15min',
                        'Appointment Reminders 15min',
                        channelDescription: 'Notifications 15 minutes before appointments',
                        importance: Importance.max,
                        priority: Priority.high,
                        showWhen: true,
                        playSound: true,
                        enableVibration: true,
                      );
                      const platformChannelSpecifics = NotificationDetails(
                        android: androidPlatformChannelSpecifics,
                      );
                      await flutterLocalNotificationsPlugin.zonedSchedule(
                        i, // ID đơn giản
                        'Lịch hẹn sắp tới - 15 phút',
                        'Lịch hẹn với $patientName vào lúc ${'$appointmentHour:00'} chỉ còn 15 phút nữa! Hãy chuẩn bị sẵn sàng.',
                        tz.TZDateTime.from(appointmentTime.subtract(Duration(minutes: 15)), vietnamTimeZone),
                        platformChannelSpecifics,
                        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
                        matchDateTimeComponents: DateTimeComponents.time,
                      );
                      print('Thông báo 15p đã được lập lịch cho ID: $i');
                    }
                  }
                }
              } catch (e) {
                print('Lỗi khi xử lý lịch hẹn $i: $e');
                continue;
              }
            }
          } else {
            print('Lỗi API: ${response.statusCode}');
          }
        }
      }
    } catch (e) {
      print('Lỗi trong Workmanager: $e');
    }
    return Future.value(true);
  });
}

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key, required this.doctorId});
  final int doctorId;

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> with SingleTickerProviderStateMixin {
  final _storage = const FlutterSecureStorage();
  List appointments = [];
  int? _doctorId;
  bool _isLoading = true;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  bool _hasExactAlarmPermission = false;

  // Thêm biến để quản lý filter
  FilterType _currentFilter = FilterType.today;

  // Initialize flutter_local_notifications
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  String getTimeSlot(dynamic slot) {
    const timeSlots = [8, 9, 10, 11, 13, 14, 15, 16];
    if (slot is int && slot >= 1 && slot <= 8) {
      return '${timeSlots[slot - 1]}:00';
    }
    return 'Chưa xác định';
  }

  // Color palette to match AppointmentDetailsScreen
  static const Color primaryColor = Color(0xFF0288D1);
  static const Color accentColor = Color(0xFFFFB300);
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color cardColor = Colors.white;
  static const Color errorColor = Color(0xFFE57373);
  static const Color textColor = Color(0xFF1A1A1A);

  @override
  void initState() {
    super.initState();
    // Initialize animation controller and slide animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuad,
    ));
    // Initialize Firebase, timezone, notifications, and background fetch
    _initializeFirebase();
    _initializeTimezone();
    _initializeNotifications();
    _scheduleBackgroundFetch();
    // Start animation and load data

    if (mounted) {
      _animationController.forward();
    }
    _loadDoctorIdAndFetch();
  }

  // Initialize Firebase
  Future<void> _initializeFirebase() async {
    try {
      await Firebase.initializeApp();
      print('Firebase khởi tạo thành công');
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        // Xử lý thông báo khi ứng dụng đang chạy
        if (message.notification != null) {
          print('Thông báo khi ứng dụng chạy: ${message.notification!.title}');
          // Có thể hiển thị thông báo cục bộ hoặc cập nhật giao diện
        }
      });
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      // Lấy FCM token để gửi cho server
      String? token = await messaging.getToken();
      if (token != null) {
        print('FCM Token: $token');
        // Gửi token này đến server để server gửi thông báo đẩy
      }else {
        print('Không lấy được FCM Token');
      }
    }catch (e) {
      print('Lỗi khởi tạo Firebase: $e');
    }
  }

  // Initialize timezone
  Future<void> _initializeTimezone() async {
    tz.initializeTimeZones();
  }

  // Initialize notification settings
  // Cải thiện hàm _initializeNotifications
  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Tạo notification channels
    const AndroidNotificationChannel channel15min = AndroidNotificationChannel(
      'appointment_channel_15min',
      'Appointment Reminders 15min',
      description: 'Notifications 15 minutes before appointments',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    const AndroidNotificationChannel testChannel = AndroidNotificationChannel(
      'test_notification_channel',
      'Test Notifications',
      description: 'Test notifications for 1 minute',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    final androidPlugin = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(channel15min);
      await androidPlugin.createNotificationChannel(testChannel);

      // Yêu cầu quyền thông báo
      final granted = await androidPlugin.requestNotificationsPermission();
      print('Quyền thông báo Android: ${granted ?? false}');
    }

    // Kiểm tra và xử lý quyền SCHEDULE_EXACT_ALARM
    await _checkAndRequestExactAlarmPermission();
  }

  // Hàm mới để kiểm tra và yêu cầu quyền exact alarm
  Future<void> _checkAndRequestExactAlarmPermission() async {
    if (!Platform.isAndroid) {
      _hasExactAlarmPermission = true;
      return;
    }

    try {
      // Kiểm tra phiên bản Android
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;

      // Android 12 (API level 31) trở lên mới cần quyền này
      if (androidInfo.version.sdkInt < 31) {
        _hasExactAlarmPermission = true;
        print('Android < 12: Không cần quyền SCHEDULE_EXACT_ALARM');
        return;
      }

      // Kiểm tra quyền hiện tại
      final alarmPermission = await Permission.scheduleExactAlarm.status;

      if (alarmPermission.isGranted) {
        _hasExactAlarmPermission = true;
        print('Quyền SCHEDULE_EXACT_ALARM đã được cấp');
        return;
      }

      // Yêu cầu quyền nếu chưa có
      print('Yêu cầu quyền SCHEDULE_EXACT_ALARM...');
      final result = await Permission.scheduleExactAlarm.request();

      _hasExactAlarmPermission = result.isGranted;

      if (_hasExactAlarmPermission) {
        print('✅ Quyền SCHEDULE_EXACT_ALARM đã được cấp');
      } else {
        print('❌ Quyền SCHEDULE_EXACT_ALARM bị từ chối');
        // Hiển thị dialog hướng dẫn người dùng
        _showExactAlarmPermissionDialog();
      }

    } catch (e) {
      print('Lỗi khi kiểm tra quyền SCHEDULE_EXACT_ALARM: $e');
      _hasExactAlarmPermission = false;
    }
  }

  // Dialog hướng dẫn người dùng cấp quyền
  void _showExactAlarmPermissionDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Cần quyền thông báo chính xác',
            style: GoogleFonts.lora(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Để nhận thông báo đúng giờ, vui lòng:\n\n'
                '1. Vào Cài đặt > Ứng dụng\n'
                '2. Tìm ứng dụng này\n'
                '3. Chọn "Quyền đặc biệt"\n'
                '4. Bật "Báo thức và nhắc nhở"',
            style: GoogleFonts.lora(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Đã hiểu', style: GoogleFonts.lora()),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: Text('Mở cài đặt', style: GoogleFonts.lora()),
            ),
          ],
        );
      },
    );
  }

  // Schedule notification for appointment (chỉ 15 phút)
  // Cải thiện hàm _scheduleNotification
  Future<void> _scheduleNotification({
    required int id,
    required String patientName,
    required String timeSlot,
    required DateTime appointmentTime,
  }) async {
    try {
      final vietnamTimeZone = tz.getLocation('Asia/Ho_Chi_Minh');
      final currentTime = DateTime.now();
      final timeUntilAppointment = appointmentTime.difference(currentTime);

      // Chỉ thông báo trước 15 phút nếu còn thời gian
      if (timeUntilAppointment.inMinutes <= 0) {
        print('Lịch hẹn đã qua, không lập thông báo');
        return;
      }

      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'appointment_channel_15min',
        'Appointment Reminders 15min',
        channelDescription: 'Notifications 15 minutes before appointments',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        playSound: true,
        enableVibration: true,
        styleInformation: BigTextStyleInformation(
          'Lịch hẹn với $patientName vào lúc $timeSlot chỉ còn 15 phút nữa! Hãy chuẩn bị sẵn sàng.',
        ),
      );

      final NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidDetails,
      );

      final tzScheduledTime = tz.TZDateTime.from(
        appointmentTime.subtract(const Duration(minutes: 15)),
        vietnamTimeZone,
      );

      // Chọn schedule mode dựa trên quyền
      AndroidScheduleMode scheduleMode;
      if (_hasExactAlarmPermission) {
        scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;
        print('Sử dụng exact alarm mode');
      } else {
        scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
        print('Sử dụng inexact alarm mode (không có quyền exact)');
      }

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        'Lịch hẹn sắp tới - 15 phút',
        'Lịch hẹn với $patientName vào lúc $timeSlot chỉ còn 15 phút nữa! Hãy chuẩn bị sẵn sàng.',
        tzScheduledTime,
        platformChannelSpecifics,
        androidScheduleMode: scheduleMode,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      print('✅ Đã lập lịch thông báo 15p cho: $patientName lúc $tzScheduledTime (ID $id)');

    } catch (e) {
      print('❌ Lỗi khi lập lịch thông báo: $e');
      // Không throw exception để không crash app
    }
  }

  // Hàm test thông báo 1 phút
  Future<void> _scheduleTestNotification() async {
    try {
      final vietnamTimeZone = tz.getLocation('Asia/Ho_Chi_Minh');
      final now = DateTime.now();
      final testTime = now.add(const Duration(minutes: 1));

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'test_notification_channel',
        'Test Notifications',
        channelDescription: 'Test notifications for 1 minute',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        playSound: true,
        enableVibration: true,
        styleInformation: BigTextStyleInformation(
          'Đây là thông báo test sau 1 phút. Hệ thống thông báo đang hoạt động bình thường!',
        ),
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidDetails,
      );

      final tzScheduledTime = tz.TZDateTime.from(testTime, vietnamTimeZone);

      // Chọn schedule mode dựa trên quyền
      AndroidScheduleMode scheduleMode;
      if (_hasExactAlarmPermission) {
        scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;
      } else {
        scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
      }

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        999999,
        'Test Thông Báo',
        'Đây là thông báo test sau 1 phút. Hệ thống hoạt động bình thường!',
        tzScheduledTime,
        platformChannelSpecifics,
        androidScheduleMode: scheduleMode,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      print('✅ Đã lập lịch test thông báo lúc $tzScheduledTime');

      // Hiển thị thông báo xác nhận
      if (mounted) {
        final message = _hasExactAlarmPermission
            ? 'Đã hẹn thông báo test chính xác sau 1 phút!'
            : 'Đã hẹn thông báo test sau ~1 phút (không chính xác)!';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message,
              style: GoogleFonts.lora(fontSize: 14, color: Colors.white),
            ),
            backgroundColor: _hasExactAlarmPermission ? Colors.green : Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 4),
          ),
        );
      }

    } catch (e) {
      print('❌ Lỗi khi lập lịch test thông báo: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Lỗi: Không thể lập lịch thông báo. Vui lòng kiểm tra quyền ứng dụng.',
              style: GoogleFonts.lora(fontSize: 14, color: Colors.white),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // Schedule background fetch
  void _scheduleBackgroundFetch() {
    Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
    Workmanager().registerPeriodicTask(
      'fetch-appointments',
      fetchAppointmentsTask,
      frequency: Duration(minutes: 10),
      initialDelay: Duration(minutes: 2),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadDoctorIdAndFetch() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final idString = await _storage.read(key: 'doctor_id');
    if (idString != null) {
      setState(() {
        _doctorId = int.tryParse(idString);
      });
      if (_doctorId != null) {
        await fetchAppointments();
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> fetchAppointments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final url = Uri.http('10.0.2.2:8081', '/api/v1/appointments/list', {
      'doctor_id': _doctorId.toString(),
    });

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          appointments = jsonDecode(response.body);
          _errorMessage = null;
        });
        // Schedule notifications for upcoming appointments
        _scheduleNotificationsForToday();
      } else {
        setState(() {
          _errorMessage = 'Lỗi khi tải danh sách lịch hẹn: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi kết nối. Vui lòng thử lại!';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Schedule notifications for appointments today (chỉ 15 phút)
  void _scheduleNotificationsForToday() {
    final now = tz.TZDateTime.now(tz.getLocation('Asia/Ho_Chi_Minh'));
    final todayStart = tz.TZDateTime(tz.getLocation('Asia/Ho_Chi_Minh'), now.year, now.month, now.day);
    final currentTime = DateTime.now();

    print('Kiểm tra lịch hẹn để lập thông báo vào: $now');
    for (var i = 0; i < appointments.length; i++) {
      final a = appointments[i];
      if (a['status'] != 'PENDING') {
        print('Bỏ qua lịch hẹn ID ${a['appointment_id']}: Không phải PENDING');
        continue;
      }

      final medicalDay = a['medical_day'];
      if (medicalDay == null) {
        print('Bỏ qua lịch hẹn ID ${a['appointment_id']}: Không có medical_day');
        continue;
      }

      try {
        final parsedMedicalDay = DateTime.parse(medicalDay);
        if (parsedMedicalDay.isAtSameMomentAs(todayStart)) {
          final slot = a['slot'];
          const timeSlots = [8, 9, 10, 11, 13, 14, 15, 16];
          if (slot is int && slot >= 1 && slot <= 8) {
            final appointmentHour = timeSlots[slot - 1];
            final appointmentTime = DateTime(
              parsedMedicalDay.year,
              parsedMedicalDay.month,
              parsedMedicalDay.day,
              appointmentHour,
            );
            final timeUntilAppointment = appointmentTime.difference(currentTime);

            // Lập lịch thông báo nếu còn thời gian (tối đa 20 phút trước)
            if (timeUntilAppointment.inMinutes > 0 && timeUntilAppointment.inMinutes <= 20) {
              final patientName = a['patient'] != null && a['patient'].isNotEmpty
                  ? a['patient'][0]['patient_name'] ?? 'Bệnh nhân ID: ${a['patient_id']}'
                  : 'Bệnh nhân ID: ${a['patient_id'] ?? 'Không xác định'}';

              print('Lập lịch thông báo cho $patientName vào $appointmentTime');
              _scheduleNotification(
                id: i,
                patientName: patientName,
                timeSlot: getTimeSlot(slot),
                appointmentTime: appointmentTime,
              );
            } else {
              print('Lịch hẹn ID ${a['appointment_id']} không nằm trong khoảng thời gian phù hợp');
            }
          }
        }
      } catch (e) {
        print('Lỗi khi xử lý lịch hẹn ID ${a['appointment_id']}: $e');
        continue;
      }
    }
  }

  String _formatDate(String? date) {
    if (date == null) return 'Chưa xác định';
    try {
      final parsedDate = DateTime.parse(date);
      return DateFormat('dd/MM/yyyy').format(parsedDate);
    } catch (e) {
      return date;
    }
  }

  // Hàm lọc appointments theo filter type
  List _getFilteredAppointments() {
    final now = tz.TZDateTime.now(tz.getLocation('Asia/Ho_Chi_Minh'));
    final todayStart = tz.TZDateTime(tz.getLocation('Asia/Ho_Chi_Minh'), now.year, now.month, now.day);
    final currentTime = DateTime.now();
    final currentHour = currentTime.hour;

    return appointments.where((a) {
      if (a['status'] != 'PENDING') return false;

      final medicalDay = a['medical_day'];
      if (medicalDay == null) return false;

      try {
        final parsedMedicalDay = DateTime.parse(medicalDay);

        switch (_currentFilter) {
          case FilterType.today:
          // Chỉ hiển thị appointments của hôm nay và chưa qua giờ
            if (!parsedMedicalDay.isAtSameMomentAs(todayStart)) {
              return false;
            }
            final slot = a['slot'];
            const timeSlots = [8, 9, 10, 11, 13, 14, 15, 16];
            if (slot is int && slot >= 1 && slot <= 8) {
              final appointmentHour = timeSlots[slot - 1];
              return appointmentHour > currentHour; // Chỉ hiển thị những giờ chưa qua
            }
            return false;

          case FilterType.thisMonth:
          // Hiển thị appointments từ hôm nay đến hết tháng
            if (parsedMedicalDay.isBefore(todayStart)) {
              return false;
            }
            if (parsedMedicalDay.year == now.year && parsedMedicalDay.month == now.month) {
              // Nếu là hôm nay, kiểm tra giờ
              if (parsedMedicalDay.isAtSameMomentAs(todayStart)) {
                final slot = a['slot'];
                const timeSlots = [8, 9, 10, 11, 13, 14, 15, 16];
                if (slot is int && slot >= 1 && slot <= 8) {
                  final appointmentHour = timeSlots[slot - 1];
                  return appointmentHour > currentHour;
                }
                return false;
              }
              return true; // Các ngày khác trong tháng
            }
            return false;

          case FilterType.thisYear:
          // Hiển thị appointments từ hôm nay đến hết năm
            if (parsedMedicalDay.isBefore(todayStart)) {
              return false;
            }
            if (parsedMedicalDay.year == now.year) {
              // Nếu là hôm nay, kiểm tra giờ
              if (parsedMedicalDay.isAtSameMomentAs(todayStart)) {
                final slot = a['slot'];
                const timeSlots = [8, 9, 10, 11, 13, 14, 15, 16];
                if (slot is int && slot >= 1 && slot <= 8) {
                  final appointmentHour = timeSlots[slot - 1];
                  return appointmentHour > currentHour;
                }
                return false;
              }
              return true; // Các ngày khác trong năm
            }
            return false;
        }
      } catch (e) {
        return false;
      }
    }).toList();
  }

  // Widget để hiển thị filter buttons
  Widget _buildFilterButtons() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildFilterButton(
              'Hôm nay',
              FilterType.today,
              Icons.today,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildFilterButton(
              'Tháng này',
              FilterType.thisMonth,
              Icons.calendar_month,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildFilterButton(
              'Năm này',
              FilterType.thisYear,
              Icons.calendar_today,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String title, FilterType filterType, IconData icon) {
    final isSelected = _currentFilter == filterType;
    return ElevatedButton.icon(
      onPressed: () {
        setState(() {
          _currentFilter = filterType;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? primaryColor : Colors.white,
        foregroundColor: isSelected ? Colors.white : primaryColor,
        elevation: isSelected ? 3 : 1,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: primaryColor,
            width: isSelected ? 0 : 1,
          ),
        ),
      ),
      icon: Icon(icon, size: 18),
      label: Text(
        title,
        style: GoogleFonts.lora(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }

  // Widget hiển thị thông tin thông báo (cập nhật)
  // Cập nhật widget thông tin thông báo
  Widget _buildNotificationInfo() {
    final statusText = _hasExactAlarmPermission
        ? 'Thông báo chính xác: 15 phút trước giờ hẹn'
        : 'Thông báo gần đúng: ~15 phút trước giờ hẹn';

    final statusColor = _hasExactAlarmPermission ? Colors.green : Colors.orange;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            _hasExactAlarmPermission ? Icons.notifications_active : Icons.notifications,
            color: statusColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              statusText,
              style: GoogleFonts.lora(
                fontSize: 12,
                color: statusColor.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (!_hasExactAlarmPermission)
            GestureDetector(
              onTap: _showExactAlarmPermissionDialog,
              child: Icon(
                Icons.info_outline,
                color: statusColor,
                size: 16,
              ),
            ),
        ],
      ),
    );
  }

  // Widget nút test thông báo
  Widget _buildTestNotificationButton() {
    return Container(
      margin: const EdgeInsets.all(16),
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _scheduleTestNotification,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
        ),
        icon: const Icon(Icons.alarm, size: 24),
        label: Text(
          'Test Thông Báo (1 phút)',
          style: GoogleFonts.lora(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredAppointments = _getFilteredAppointments();

    // Sort appointments by medical_day and slot
    filteredAppointments.sort((a, b) {
      final dateA = a['medical_day'] != null ? DateTime.parse(a['medical_day']) : DateTime(1970);
      final dateB = b['medical_day'] != null ? DateTime.parse(b['medical_day']) : DateTime(1970);
      final dateComparison = dateA.compareTo(dateB);
      if (dateComparison == 0) {
        final slotA = a['slot'] ?? 0;
        final slotB = b['slot'] ?? 0;
        return slotA.compareTo(slotB);
      }
      return dateComparison;
    });

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildFilterButtons(),

            // Notification info
            _buildNotificationInfo(),

            // Main content
            Expanded(
              child: _isLoading
                  ? Center(
                child: CircularProgressIndicator(
                  color: accentColor,
                  strokeWidth: 4,
                ),
              )
                  : _errorMessage != null
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: errorColor,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: GoogleFonts.lora(
                        color: errorColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _loadDoctorIdAndFetch,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                      icon: const Icon(Icons.refresh, size: 20),
                      label: Text(
                        'Thử lại',
                        style: GoogleFonts.lora(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              )
                  : filteredAppointments.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event_busy,
                      color: Colors.grey[500],
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _getEmptyMessage(),
                      style: GoogleFonts.lora(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
                  : RefreshIndicator(
                onRefresh: fetchAppointments,
                color: accentColor,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredAppointments.length,
                  itemBuilder: (context, index) {
                    final a = filteredAppointments[index];
                    final patientName = a['patient'] != null && a['patient'].isNotEmpty
                        ? a['patient'][0]['patient_name'] ?? 'Bệnh nhân ID: ${a['patient_id']}'
                        : 'Bệnh nhân ID: ${a['patient_id'] ?? 'Không xác định'}';

                    return SlideTransition(
                      position: _slideAnimation,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AppointmentDetailsScreen(appointment: a),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: primaryColor.withOpacity(0.2),
                                  child: const Icon(
                                    Icons.event,
                                    color: primaryColor,
                                    size: 40,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        patientName,
                                        style: GoogleFonts.lora(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: textColor,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'ID: ${(a['appointment_id'])}',
                                        style: GoogleFonts.lora(
                                          fontSize: 14,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      Text(
                                        'Ngày khám: ${_formatDate(a['medical_day'])}',
                                        style: GoogleFonts.lora(
                                          fontSize: 14,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      Text(
                                        'Khung giờ: ${getTimeSlot(a['slot'])}',
                                        style: GoogleFonts.lora(
                                          fontSize: 14,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      // Hiển thị thông tin thông báo (cập nhật)
                                      Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.notifications,
                                              size: 12,
                                              color: accentColor,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Thông báo: 15p trước',
                                              style: GoogleFonts.lora(
                                                fontSize: 11,
                                                color: accentColor,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.grey[400],
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Test notification button
            _buildTestNotificationButton(),
          ],
        ),
      ),
    );
  }

  // Hàm để lấy message khi không có dữ liệu
  String _getEmptyMessage() {
    switch (_currentFilter) {
      case FilterType.today:
        return 'Không có lịch hẹn nào còn lại trong hôm nay';
      case FilterType.thisMonth:
        return 'Không có lịch hẹn nào trong tháng này';
      case FilterType.thisYear:
        return 'Không có lịch hẹn nào trong năm này';
    }
  }
}