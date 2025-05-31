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

// 2. SỬA TRONG callbackDispatcher (Workmanager) - Đổi 15p thành 5p
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
                  const timeSlots = [8, 9, 10, 11, 13, 14, 15, 23];
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

                    // SỬA: Chỉ thông báo trước 5 phút (thay vì 15 phút)
                    // Kiểm tra trong khoảng 10 phút để có thời gian lập lịch
                    if (timeUntilAppointment.inMinutes > 0 && timeUntilAppointment.inMinutes <= 10) {
                      print('Lập lịch thông báo 5p cho: $patientName, thời gian: $appointmentTime');

                      final androidPlatformChannelSpecifics = AndroidNotificationDetails(
                        'appointment_channel_5min', // SỬA: channel name
                        'Appointment Reminders 5min', // SỬA: channel name
                        channelDescription: 'Notifications 5 minutes before appointments', // SỬA: description
                        importance: Importance.max,
                        priority: Priority.high,
                        showWhen: true,
                        playSound: true,
                        enableVibration: true,
                        enableLights: true,
                        ledColor: Colors.blue,
                        ledOnMs: 1000,
                        ledOffMs: 500,
                        autoCancel: false,
                        styleInformation: BigTextStyleInformation(
                          'Lịch hẹn với $patientName vào lúc ${'$appointmentHour:00'} chỉ còn 5 phút nữa! Hãy chuẩn bị sẵn sàng.', // SỬA: 15p → 5p
                        ),
                      );

                      final platformChannelSpecifics = NotificationDetails(
                        android: androidPlatformChannelSpecifics,
                      );

                      await flutterLocalNotificationsPlugin.zonedSchedule(
                        i,
                        'Lịch hẹn sắp tới - 5 phút', // SỬA: title
                        'Lịch hẹn với $patientName vào lúc ${'$appointmentHour:00'} chỉ còn 5 phút nữa! Hãy chuẩn bị sẵn sàng.', // SỬA: body
                        tz.TZDateTime.from(appointmentTime.subtract(Duration(minutes: 5)), vietnamTimeZone), // SỬA: 15 → 5
                        platformChannelSpecifics,
                        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
                      );
                      print('Thông báo 5p đã được lập lịch cho ID: $i'); // SỬA: log
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

// 1. SỬA TIMESLOTS: Đổi 16 thành 23
  String getTimeSlot(dynamic slot) {
    const timeSlots = [8, 9, 10, 11, 13, 14, 15, 23]; // Đổi 16 thành 23
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

// Thêm hàm này vào class _AppointmentsScreenState
  Future<void> _checkAndRequestPermissionsBasedOnVersion() async {
    if (!Platform.isAndroid) return;

    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final sdkVersion = androidInfo.version.sdkInt;

      print('Android SDK Version: $sdkVersion');

      // Xử lý quyền dựa trên phiên bản Android
      if (sdkVersion >= 33) {
        // Android 13+ (API 33+)
        print('Android 13+: Kiểm tra quyền thông báo và exact alarm');

        // Kiểm tra quyền thông báo
        final notificationStatus = await Permission.notification.status;
        if (!notificationStatus.isGranted) {
          await Permission.notification.request();
        }

        // Kiểm tra quyền exact alarm
        final exactAlarmStatus = await Permission.scheduleExactAlarm.status;
        if (!exactAlarmStatus.isGranted) {
          await Permission.scheduleExactAlarm.request();
        }

        _hasExactAlarmPermission = await Permission.scheduleExactAlarm.isGranted;

      } else if (sdkVersion >= 31) {
        // Android 12 (API 31-32)
        print('Android 12: Kiểm tra quyền exact alarm');

        final exactAlarmStatus = await Permission.scheduleExactAlarm.status;
        if (!exactAlarmStatus.isGranted) {
          await Permission.scheduleExactAlarm.request();
        }

        _hasExactAlarmPermission = await Permission.scheduleExactAlarm.isGranted;

      } else {
        // Android 11 hoặc thấp hơn (API <= 30)
        print('Android 11 hoặc thấp hơn: Không cần quyền đặc biệt cho exact alarm');
        _hasExactAlarmPermission = true;
      }

      // Kiểm tra quyền tối ưu hóa pin (tất cả phiên bản từ Android 6+)
      if (sdkVersion >= 23) {
        await _requestDisableBatteryOptimization();
      }

      print('Trạng thái quyền exact alarm: $_hasExactAlarmPermission');

    } catch (e) {
      print('Lỗi khi kiểm tra phiên bản và quyền: $e');
      _hasExactAlarmPermission = false;
    }
  }

// Cập nhật hàm _requestDisableBatteryOptimization
  Future<void> _requestDisableBatteryOptimization() async {
    if (!Platform.isAndroid) return;

    try {
      // Kiểm tra quyền
      final status = await Permission.ignoreBatteryOptimizations.status;
      print('Trạng thái tối ưu hóa pin: $status');

      if (!status.isGranted) {
        // Yêu cầu quyền
        final result = await Permission.ignoreBatteryOptimizations.request();
        print('Kết quả yêu cầu tắt tối ưu hóa pin: $result');

        if (!result.isGranted && mounted) {
          // Hiển thị hướng dẫn thủ công
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Cần tắt tối ưu hóa pin', style: GoogleFonts.lora(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Để thông báo hoạt động đúng giờ, vui lòng:',
                    style: GoogleFonts.lora(),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '1. Vào Cài đặt > Ứng dụng > esavior_doctor',
                    style: GoogleFonts.lora(fontSize: 14),
                  ),
                  Text(
                    '2. Chọn "Pin" hoặc "Tiết kiệm pin"',
                    style: GoogleFonts.lora(fontSize: 14),
                  ),
                  Text(
                    '3. Chọn "Không tối ưu hóa" hoặc "Không giới hạn"',
                    style: GoogleFonts.lora(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Mỗi thiết bị có thể có cách thực hiện khác nhau.',
                    style: GoogleFonts.lora(fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Để sau', style: GoogleFonts.lora()),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    openAppSettings();
                  },
                  child: Text('Mở cài đặt', style: GoogleFonts.lora()),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      print('Lỗi khi yêu cầu tắt tối ưu hóa pin: $e');
    }
  }

// Cập nhật hàm _initializeNotifications
  Future<void> _initializeNotifications() async {
    // Khởi tạo plugin
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('Người dùng nhấn vào thông báo: ${response.payload}');
      },
    );

    // Tạo kênh thông báo với cài đặt mạnh hơn
    const AndroidNotificationChannel highImportanceChannel = AndroidNotificationChannel(
      'high_importance_channel',  // ID
      'Thông báo quan trọng',     // Tên
      description: 'Thông báo lịch hẹn và nhắc nhở quan trọng',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      ledColor: Color.fromARGB(255, 255, 0, 0),
      showBadge: true,
    );

    final androidPlugin = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(highImportanceChannel);

      // Yêu cầu quyền thông báo
      final granted = await androidPlugin.requestNotificationsPermission();
      print('Quyền thông báo Android: ${granted ?? false}');

      // Kiểm tra các kênh đã tạo
      final channels = await androidPlugin.getNotificationChannels();
      if (channels != null) {
        for (var channel in channels) {
          print('Kênh: ${channel.id} - ${channel.name} - Importance: ${channel.importance}');
        }
      }
    }

    // Kiểm tra và yêu cầu quyền dựa trên phiên bản Android
    await _checkAndRequestPermissionsBasedOnVersion();
  }

// Thêm hàm test thông báo nhanh (5 giây)
  Future<void> _testQuickNotification() async {
    try {
      final now = DateTime.now();
      final scheduledTime = now.add(const Duration(seconds: 5));

      // Sử dụng thông báo đơn giản nhất có thể
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'high_importance_channel',
        'Thông báo quan trọng',
        channelDescription: 'Thông báo lịch hẹn và nhắc nhở quan trọng',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        autoCancel: false,
      );

      final NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidDetails,
      );

      // Lập lịch thông báo sau 5 giây
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        888,
        'Test nhanh - 5 giây',
        'Thông báo này sẽ hiển thị sau 5 giây. Thời gian lập: ${now.toString()}',
        tz.TZDateTime.from(scheduledTime, tz.getLocation('Asia/Ho_Chi_Minh')),
        platformChannelSpecifics,
        androidScheduleMode: _hasExactAlarmPermission
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
      );

      print('✅ Đã lập lịch thông báo nhanh sau 5 giây');
      print('  - Thời gian hiện tại: $now');
      print('  - Thời gian dự kiến: $scheduledTime');
      print('  - Exact alarm permission: $_hasExactAlarmPermission');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã lập lịch thông báo sau 5 giây',
              style: GoogleFonts.lora(fontSize: 14, color: Colors.white),
            ),
            backgroundColor: Colors.blue,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ Lỗi khi lập lịch thông báo nhanh: $e');
    }
  }

  // Thêm hàm test thông báo ngay lập tức để kiểm tra
  Future<void> _showImmediateNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'test_notification_channel',
      'Test Notifications',
      channelDescription: 'Test notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      0,
      'Thông báo ngay lập tức',
      'Đây là thông báo test ngay lập tức để kiểm tra hệ thống!',
      platformChannelSpecifics,
    );

    print('✅ Đã hiển thị thông báo ngay lập tức');
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

// 1. SỬA HÀM _scheduleNotification - Đổi 15p thành 5p
  Future<void> _scheduleNotification({
    required int id,
    required String patientName,
    required String timeSlot,
    required DateTime appointmentTime,
  }) async {
    try {
      final vietnamTimeZone = tz.getLocation('Asia/Ho_Chi_Minh');
      final currentTime = DateTime.now();

      // Tính thời gian thông báo (5 phút trước giờ hẹn) - SỬA: 15p → 5p
      final notificationTime = appointmentTime.subtract(const Duration(minutes: 5));

      // Kiểm tra xem thời gian thông báo đã qua chưa
      if (notificationTime.isBefore(currentTime)) {
        print('⚠️ Thời gian thông báo đã qua, không thể lập lịch cho: $patientName lúc $timeSlot');

        // Nếu thời gian thông báo đã qua nhưng lịch hẹn vẫn còn trong tương lai
        // và còn ít nhất 1 phút, thì hiển thị thông báo ngay lập tức
        if (appointmentTime.isAfter(currentTime) &&
            appointmentTime.difference(currentTime).inMinutes >= 1) {

          print('🔄 Chuyển sang thông báo ngay lập tức vì thời gian thông báo đã qua');

          final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
            'appointment_immediate_channel',
            'Immediate Appointment Reminders',
            channelDescription: 'Immediate notifications for upcoming appointments',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
            playSound: true,
            enableVibration: true,
            enableLights: true,
            ledColor: Colors.red,
            ledOnMs: 1000,
            ledOffMs: 500,
          );

          final NotificationDetails platformChannelSpecifics = NotificationDetails(
            android: androidDetails,
          );

          // Hiển thị thông báo ngay lập tức thay vì lập lịch
          await _flutterLocalNotificationsPlugin.show(
            id,
            'Lịch hẹn sắp tới!',
            'Lịch hẹn với $patientName vào lúc $timeSlot sắp diễn ra! Còn ${appointmentTime.difference(currentTime).inMinutes} phút nữa.',
            platformChannelSpecifics,
          );

          print('✅ Đã hiển thị thông báo ngay lập tức cho: $patientName lúc $timeSlot');
        }

        return;
      }

      final timeUntilAppointment = appointmentTime.difference(currentTime);

      if (timeUntilAppointment.inMinutes <= 0) {
        print('Lịch hẹn đã qua, không lập thông báo');
        return;
      }

      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'appointment_channel_5min', // SỬA: channel name
        'Appointment Reminders 5min', // SỬA: channel name
        channelDescription: 'Notifications 5 minutes before appointments', // SỬA: description
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        playSound: true,
        enableVibration: true,
        // SỬA: Nội dung thông báo 15p → 5p
        styleInformation: BigTextStyleInformation(
          'Lịch hẹn với $patientName vào lúc $timeSlot chỉ còn 5 phút nữa! Hãy chuẩn bị sẵn sàng.',
        ),
        enableLights: true,
        ledColor: Colors.blue,
        ledOnMs: 1000,
        ledOffMs: 500,
      );

      final NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidDetails,
      );

      final tzScheduledTime = tz.TZDateTime.from(
        notificationTime,
        vietnamTimeZone,
      );

      AndroidScheduleMode scheduleMode = _hasExactAlarmPermission
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        'Lịch hẹn sắp tới - 5 phút', // SỬA: title
        'Lịch hẹn với $patientName vào lúc $timeSlot chỉ còn 5 phút nữa! Hãy chuẩn bị sẵn sàng.', // SỬA: body
        tzScheduledTime,
        platformChannelSpecifics,
        androidScheduleMode: scheduleMode,
      );

      print('✅ Đã lập lịch thông báo 5p cho: $patientName lúc $tzScheduledTime (ID $id)'); // SỬA: log

    } catch (e) {
      print('❌ Lỗi khi lập lịch thông báo: $e');
    }
  }

// Thay thế hàm _scheduleTestNotification đã sửa lỗi const
  Future<void> _scheduleTestNotification() async {
    try {
      final vietnamTimeZone = tz.getLocation('Asia/Ho_Chi_Minh');
      final now = DateTime.now();
      final testTime = now.add(const Duration(minutes: 1));

      // Loại bỏ const vì sử dụng BigTextStyleInformation
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'test_notification_channel',
        'Test Notifications',
        channelDescription: 'Test notifications for 1 minute',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        playSound: true,
        enableVibration: true,
        styleInformation: const BigTextStyleInformation(
          'Đây là thông báo test sau 1 phút. Hệ thống thông báo đang hoạt động bình thường!',
        ),
      );

      final NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidDetails,
      );

      final tzScheduledTime = tz.TZDateTime.from(testTime, vietnamTimeZone);

      AndroidScheduleMode scheduleMode = _hasExactAlarmPermission
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        999999,
        'Test Thông Báo',
        'Đây là thông báo test sau 1 phút. Hệ thống hoạt động bình thường!',
        tzScheduledTime,
        platformChannelSpecifics,
        androidScheduleMode: scheduleMode,
      );

      print('✅ Đã lập lịch test thông báo lúc $tzScheduledTime');

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

// 3. SỬA TRONG _scheduleNotificationsForToday() - Đổi điều kiện từ 20p thành 10p
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
          const timeSlots = [8, 9, 10, 11, 13, 14, 15, 23];
          if (slot is int && slot >= 1 && slot <= 8) {
            final appointmentHour = timeSlots[slot - 1];
            final appointmentTime = DateTime(
              parsedMedicalDay.year,
              parsedMedicalDay.month,
              parsedMedicalDay.day,
              appointmentHour,
            );
            final timeUntilAppointment = appointmentTime.difference(currentTime);

            // SỬA: Lập lịch thông báo nếu còn thời gian (tối đa 10 phút trước thay vì 20 phút)
            if (timeUntilAppointment.inMinutes > 0 && timeUntilAppointment.inMinutes <= 10) {
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

  // Thêm hàm kiểm tra thông báo đã lập lịch
  Future<void> _checkPendingNotifications() async {
    try {
      final pendingNotifications = await _flutterLocalNotificationsPlugin.pendingNotificationRequests();

      print('Số lượng thông báo đang chờ: ${pendingNotifications.length}');

      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(
                'Thông báo đã lập lịch',
                style: GoogleFonts.lora(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tổng số: ${pendingNotifications.length} thông báo',
                      style: GoogleFonts.lora(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    ...pendingNotifications.map((notification) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        'ID: ${notification.id} - ${notification.title ?? "Không có tiêu đề"}',
                        style: GoogleFonts.lora(fontSize: 12),
                      ),
                    )).toList(),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Đóng', style: GoogleFonts.lora()),
                ),
                if (pendingNotifications.isNotEmpty)
                  TextButton(
                    onPressed: () async {
                      await _flutterLocalNotificationsPlugin.cancelAll();
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Đã hủy tất cả thông báo đã lập lịch',
                            style: GoogleFonts.lora(),
                          ),
                        ),
                      );
                    },
                    child: Text('Hủy tất cả', style: GoogleFonts.lora(color: Colors.red)),
                  ),
              ],
            );
          },
        );
      }
    } catch (e) {
      print('Lỗi khi kiểm tra thông báo: $e');
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

// 3. SỬA TRONG _getFilteredAppointments()
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
            const timeSlots = [8, 9, 10, 11, 13, 14, 15, 23]; // SỬA: Đổi 16 thành 23
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
                const timeSlots = [8, 9, 10, 11, 13, 14, 15, 23]; // SỬA: Đổi 16 thành 23
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
                const timeSlots = [8, 9, 10, 11, 13, 14, 15, 23]; // SỬA: Đổi 16 thành 23
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
              'Theo tháng',
              FilterType.thisMonth,
              Icons.calendar_month,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildFilterButton(
              'Theo năm',
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

// 4. SỬA WIDGET THÔNG TIN THÔNG BÁO
  Widget _buildNotificationInfo() {
    final statusText = _hasExactAlarmPermission
        ? 'Thông báo chính xác: 5 phút trước giờ hẹn' // SỬA: 15p → 5p
        : 'Thông báo gần đúng: ~5 phút trước giờ hẹn'; // SỬA: 15p → 5p

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

  // Thêm hàm kiểm tra quyền chi tiết
  Future<void> _checkDetailedPermissions() async {
    print('\n=== KIỂM TRA QUYỀN CHI TIẾT ===');

    // Kiểm tra quyền thông báo cơ bản
    final androidPlugin = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      final notificationPermission = await androidPlugin.areNotificationsEnabled();
      print('Quyền thông báo cơ bản: $notificationPermission');
    }

    // Kiểm tra quyền exact alarm
    if (Platform.isAndroid) {
      try {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        print('Android SDK: ${androidInfo.version.sdkInt}');

        if (androidInfo.version.sdkInt >= 31) {
          final exactAlarmStatus = await Permission.scheduleExactAlarm.status;
          print('Quyền SCHEDULE_EXACT_ALARM: $exactAlarmStatus');
          _hasExactAlarmPermission = exactAlarmStatus.isGranted;
        } else {
          _hasExactAlarmPermission = true;
          print('Android < 12: Không cần quyền SCHEDULE_EXACT_ALARM');
        }
      } catch (e) {
        print('Lỗi kiểm tra quyền: $e');
      }
    }

    // Kiểm tra notification channels
    if (androidPlugin != null) {
      try {
        final channels = await androidPlugin.getNotificationChannels();
        print('Số lượng notification channels: ${channels?.length ?? 0}');
        if (channels != null) {
          for (var channel in channels) {
            print('Channel: ${channel.id} - ${channel.name} - Importance: ${channel.importance}');
          }
        }
      } catch (e) {
        print('Lỗi kiểm tra channels: $e');
      }
    }

    print('=== KẾT THÚC KIỂM TRA ===\n');
  }

// Cải tiến hàm test thông báo với nhiều khoảng thời gian
  Future<void> _scheduleMultipleTestNotifications() async {
    try {
      await _checkDetailedPermissions();

      final vietnamTimeZone = tz.getLocation('Asia/Ho_Chi_Minh');
      final now = DateTime.now();

      print('\n=== LẬP LỊCH NHIỀU THÔNG BÁO TEST ===');
      print('Thời gian hiện tại: $now');

      // Test sau 30 giây
      await _scheduleTestNotificationWithDelay(
        id: 100,
        title: 'Test 30 giây',
        body: 'Thông báo test sau 30 giây',
        delaySeconds: 30,
      );

      // Test sau 1 phút
      await _scheduleTestNotificationWithDelay(
        id: 101,
        title: 'Test 1 phút',
        body: 'Thông báo test sau 1 phút',
        delaySeconds: 60,
      );

      // Test sau 2 phút
      await _scheduleTestNotificationWithDelay(
        id: 102,
        title: 'Test 2 phút',
        body: 'Thông báo test sau 2 phút',
        delaySeconds: 120,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã lập lịch 3 thông báo test: 30s, 1p, 2p',
              style: GoogleFonts.lora(fontSize: 14, color: Colors.white),
            ),
            backgroundColor: Colors.blue,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 4),
          ),
        );
      }

    } catch (e) {
      print('❌ Lỗi khi lập lịch multiple test: $e');
    }
  }

// Hàm helper để lập lịch thông báo với delay cụ thể
  Future<void> _scheduleTestNotificationWithDelay({
    required int id,
    required String title,
    required String body,
    required int delaySeconds,
  }) async {
    try {
      final vietnamTimeZone = tz.getLocation('Asia/Ho_Chi_Minh');
      final now = DateTime.now();
      final scheduledTime = now.add(Duration(seconds: delaySeconds));

      // Tạo notification details với ID channel cụ thể
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'test_notification_channel',
        'Test Notifications',
        channelDescription: 'Test notifications for debugging',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        ledColor: Colors.red,
        ledOnMs: 1000,
        ledOffMs: 500,
        autoCancel: false,
        ongoing: false,
        styleInformation: BigTextStyleInformation(
          '$body\nThời gian lập lịch: ${now.toString()}\nThời gian dự kiến: ${scheduledTime.toString()}',
        ),
      );

      final NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidDetails,
      );

      final tzScheduledTime = tz.TZDateTime.from(scheduledTime, vietnamTimeZone);

      print('Lập lịch thông báo ID $id:');
      print('  - Thời gian hiện tại: $now');
      print('  - Thời gian lập lịch: $scheduledTime');
      print('  - TZ Scheduled time: $tzScheduledTime');
      print('  - Delay: $delaySeconds giây');
      print('  - Exact alarm permission: $_hasExactAlarmPermission');

      AndroidScheduleMode scheduleMode = _hasExactAlarmPermission
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzScheduledTime,
        platformChannelSpecifics,
        androidScheduleMode: scheduleMode,
      );

      print('✅ Đã lập lịch thông báo ID $id thành công');

    } catch (e) {
      print('❌ Lỗi khi lập lịch thông báo ID $id: $e');
    }
  }

// Cải tiến hàm kiểm tra thông báo pending
  Future<void> _checkPendingNotificationsDetailed() async {
    try {
      final pendingNotifications = await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
      final now = DateTime.now();

      print('\n=== THÔNG BÁO ĐANG CHỜ ===');
      print('Thời gian kiểm tra: $now');
      print('Số lượng thông báo đang chờ: ${pendingNotifications.length}');

      for (var notification in pendingNotifications) {
        print('ID: ${notification.id}');
        print('  - Tiêu đề: ${notification.title}');
        print('  - Nội dung: ${notification.body}');
        print('  - Payload: ${notification.payload}');
        print('---');
      }
      print('=== KẾT THÚC ===\n');

      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(
                'Thông báo đã lập lịch',
                style: GoogleFonts.lora(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thời gian kiểm tra: ${DateFormat('HH:mm:ss dd/MM/yyyy').format(now)}',
                      style: GoogleFonts.lora(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tổng số: ${pendingNotifications.length} thông báo',
                      style: GoogleFonts.lora(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    ...pendingNotifications.map((notification) => Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ID: ${notification.id}',
                            style: GoogleFonts.lora(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Tiêu đề: ${notification.title ?? "Không có"}',
                            style: GoogleFonts.lora(fontSize: 11),
                          ),
                          Text(
                            'Nội dung: ${notification.body ?? "Không có"}',
                            style: GoogleFonts.lora(fontSize: 11),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    )).toList(),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Đóng', style: GoogleFonts.lora()),
                ),
                if (pendingNotifications.isNotEmpty)
                  TextButton(
                    onPressed: () async {
                      await _flutterLocalNotificationsPlugin.cancelAll();
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Đã hủy tất cả ${pendingNotifications.length} thông báo',
                            style: GoogleFonts.lora(),
                          ),
                        ),
                      );
                    },
                    child: Text('Hủy tất cả', style: GoogleFonts.lora(color: Colors.red)),
                  ),
              ],
            );
          },
        );
      }
    } catch (e) {
      print('Lỗi khi kiểm tra thông báo: $e');
    }
  }

// Hàm kiểm tra và yêu cầu tắt tối ưu hóa pin
  Future<void> _requestBatteryOptimizationDisable() async {
    if (Platform.isAndroid) {
      try {
        final status = await Permission.ignoreBatteryOptimizations.status;
        print('Trạng thái tối ưu hóa pin: $status');

        if (!status.isGranted) {
          if (mounted) {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text(
                    'Tắt tối ưu hóa pin',
                    style: GoogleFonts.lora(fontWeight: FontWeight.bold),
                  ),
                  content: Text(
                    'Để thông báo hoạt động đúng cách, vui lòng tắt tối ưu hóa pin cho ứng dụng này.\n\n'
                        'Điều này sẽ đảm bảo thông báo được hiển thị đúng giờ.',
                    style: GoogleFonts.lora(),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Bỏ qua', style: GoogleFonts.lora()),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await Permission.ignoreBatteryOptimizations.request();
                      },
                      child: Text('Cài đặt', style: GoogleFonts.lora()),
                    ),
                  ],
                );
              },
            );
          }
        }
      } catch (e) {
        print('Lỗi kiểm tra tối ưu hóa pin: $e');
      }
    }
  }
  // Sửa lại hàm _scheduleOneMinuteNotification() để khắc phục lỗi LED
  Future<void> _scheduleOneMinuteNotification() async {
    try {
      final vietnamTimeZone = tz.getLocation('Asia/Ho_Chi_Minh');
      final now = DateTime.now();
      final scheduledTime = now.add(const Duration(minutes: 1));

      // Sửa lại AndroidNotificationDetails để tránh lỗi LED
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'one_minute_channel',
        'One Minute Notifications',
        channelDescription: 'Notifications scheduled for 1 minute',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        // Sửa lại cấu hình LED để tránh lỗi
        ledColor: Colors.blue,
        ledOnMs: 1000,  // Thêm dòng này
        ledOffMs: 500,  // Thêm dòng này
        autoCancel: false,
        styleInformation: const BigTextStyleInformation(
          'Đã đúng 1 phút! Thông báo này được lập lịch từ trước.',
        ),
      );

      final NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidDetails,
      );

      final tzScheduledTime = tz.TZDateTime.from(scheduledTime, vietnamTimeZone);

      AndroidScheduleMode scheduleMode = _hasExactAlarmPermission
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        777, // ID duy nhất cho thông báo 1 phút
        'Thông báo 1 phút ⏰',
        'Đã đúng 1 phút kể từ khi bạn nhấn nút!',
        tzScheduledTime,
        platformChannelSpecifics,
        androidScheduleMode: scheduleMode,
      );

      print('✅ Đã lập lịch thông báo 1 phút lúc: $tzScheduledTime');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã hẹn thông báo sau 1 phút! 🔔',
              style: GoogleFonts.lora(fontSize: 14, color: Colors.white),
            ),
            backgroundColor: Colors.purple,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Hủy',
              textColor: Colors.white,
              onPressed: () async {
                await _flutterLocalNotificationsPlugin.cancel(777);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã hủy thông báo 1 phút', style: GoogleFonts.lora()),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
        );
      }

    } catch (e) {
      print('❌ Lỗi khi lập lịch thông báo 1 phút: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Lỗi: Không thể lập lịch thông báo 1 phút',
              style: GoogleFonts.lora(fontSize: 14, color: Colors.white),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
// Update your _buildTestNotificationButton method to include the 1-minute button
  Widget _buildTestNotificationButton() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Nút test ngay lập tức
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showImmediateNotification,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
              ),
              icon: const Icon(Icons.notifications, size: 24),
              label: Text(
                'Test Thông Báo Ngay',
                style: GoogleFonts.lora(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // NÚT MỚI: Test sau 1 phút
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _scheduleOneMinuteNotification,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
              ),
              icon: const Icon(Icons.alarm, size: 24),
              label: Text(
                'Thông Báo Sau 1 Phút ⏰',
                style: GoogleFonts.lora(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Nút test sau 5 giây
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _testQuickNotification,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
              ),
              icon: const Icon(Icons.timer, size: 24),
              label: Text(
                'Test Sau 5 Giây',
                style: GoogleFonts.lora(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Các nút khác
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _requestDisableBatteryOptimization,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  icon: const Icon(Icons.battery_saver, size: 20),
                  label: Text(
                    'Tắt tối ưu pin',
                    style: GoogleFonts.lora(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _checkPendingNotificationsDetailed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  icon: const Icon(Icons.list, size: 20),
                  label: Text(
                    'Kiểm tra',
                    style: GoogleFonts.lora(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
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