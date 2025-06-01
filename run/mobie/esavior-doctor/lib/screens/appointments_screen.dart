import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:workmanager/workmanager.dart';
import 'appointment_details_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:math' as math;

// Enum để định nghĩa các loại filter
enum FilterType { today, thisMonth, thisYear }

// Hàm xử lý thông báo đẩy khi ứng dụng ở chế độ nền
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
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
      await initializeDateFormatting('vi', null);

      final storage = FlutterSecureStorage();
      final idString = await storage.read(key: 'doctor_id');

      final notificationsEnabled = await storage.read(key: 'notifications_enabled');
      final reminderMinutes = await storage.read(key: 'reminder_minutes');
      final exactTimeNotification = await storage.read(key: 'exact_time_notification');

      final isNotificationsEnabled = notificationsEnabled != 'false';
      final reminderMinutesValue = int.tryParse(reminderMinutes ?? '15') ?? 15;
      final isExactTimeEnabled = exactTimeNotification != 'false';

      if (!isNotificationsEnabled) {
        print('Thông báo đã bị tắt trong cài đặt');
        return Future.value(true);
      }

      if (idString != null) {
        final doctorId = int.tryParse(idString);
        if (doctorId != null) {
          final url = Uri.http('10.0.2.2:8081', '/api/v1/appointments/list', {
            'doctor_id': doctorId.toString(),
          });
          final response = await http.get(url);
          print('API response status: ${response.statusCode}');
          if (response.statusCode == 200) {
            final appointments = jsonDecode(response.body) as List<dynamic>;
            print('Số lượng lịch hẹn nhận được: ${appointments.length}');
            final now = tz.TZDateTime.now(tz.getLocation('Asia/Ho_Chi_Minh'));
            final todayStart = tz.TZDateTime(tz.getLocation('Asia/Ho_Chi_Minh'), now.year, now.month, now.day);
            final currentTime = DateTime.now();
            final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
            final vietnamTimeZone = tz.getLocation('Asia/Ho_Chi_Minh');

            for (var i = 0; i < appointments.length; i++) {
              final Map<String, dynamic> a = Map<String, dynamic>.from(appointments[i]);
              if (a['status'] != 'PENDING') continue;
              final medicalDay = a['medical_day'];
              if (medicalDay == null) continue;

              try {
                final parsedMedicalDay = DateTime.parse(medicalDay.toString());
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

                    final patientList = a['patient'] as List<dynamic>?;
                    final patientName = patientList != null && patientList.isNotEmpty
                        ? (patientList[0] as Map<String, dynamic>)['patient_name']?.toString() ?? 'Bệnh nhân ID: ${a['patient_id']}'
                        : 'Bệnh nhân ID: ${a['patient_id'] ?? 'Không xác định'}';

                    if (timeUntilAppointment.inMinutes > 0 && timeUntilAppointment.inMinutes <= (reminderMinutesValue + 5)) {
                      print('Lập lịch thông báo ${reminderMinutesValue}p cho: $patientName, thời gian: $appointmentTime');

                      final androidPlatformChannelSpecifics = AndroidNotificationDetails(
                        'appointment_channel_${reminderMinutesValue}min',
                        'Appointment Reminders ${reminderMinutesValue}min',
                        channelDescription: 'Notifications $reminderMinutesValue minutes before appointments',
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
                          'Lịch hẹn với $patientName vào lúc ${'$appointmentHour:00'} chỉ còn $reminderMinutesValue phút nữa! Hãy chuẩn bị sẵn sàng.',
                        ),
                      );

                      final platformChannelSpecifics = NotificationDetails(
                        android: androidPlatformChannelSpecifics,
                      );

                      await flutterLocalNotificationsPlugin.zonedSchedule(
                        i,
                        'Lịch hẹn sắp tới - $reminderMinutesValue phút',
                        'Lịch hẹn với $patientName vào lúc ${'$appointmentHour:00'} chỉ còn $reminderMinutesValue phút nữa! Hãy chuẩn bị sẵn sàng.',
                        tz.TZDateTime.from(appointmentTime.subtract(Duration(minutes: reminderMinutesValue)), vietnamTimeZone),
                        platformChannelSpecifics,
                        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
                      );
                      print('Thông báo ${reminderMinutesValue}p đã được lập lịch cho ID: $i');

                      if (isExactTimeEnabled) {
                        final nearTimeAndroidDetails = AndroidNotificationDetails(
                          'appointment_near_time_channel',
                          'Appointment Near Time',
                          channelDescription: 'Notifications 2 minutes before appointment time',
                          importance: Importance.max,
                          priority: Priority.high,
                          showWhen: true,
                          playSound: true,
                          enableVibration: true,
                          enableLights: true,
                          ledColor: Colors.green,
                          ledOnMs: 1000,
                          ledOffMs: 500,
                          autoCancel: false,
                          styleInformation: BigTextStyleInformation(
                            'Đã đến giờ khám với $patientName! Lịch hẹn lúc ${'$appointmentHour:00'} đã bắt đầu.',
                          ),
                        );

                        final nearTimePlatformSpecifics = NotificationDetails(
                          android: nearTimeAndroidDetails,
                        );

                        await flutterLocalNotificationsPlugin.zonedSchedule(
                          i + 10000,
                          'Đã đến giờ khám!',
                          'Đã đến giờ khám với $patientName! Lịch hẹn lúc ${'$appointmentHour:00'} đã bắt đầu.',
                          tz.TZDateTime.from(appointmentTime.subtract(Duration(minutes: 2)), vietnamTimeZone),
                          nearTimePlatformSpecifics,
                          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
                        );
                        print('Thông báo "đã đến giờ khám" (2p trước) đã được lập lịch cho ID: ${i + 10000}');
                      }
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

class _AppointmentsScreenState extends State<AppointmentsScreen> with TickerProviderStateMixin {
  final _storage = const FlutterSecureStorage();
  List<dynamic> appointments = [];
  int? _doctorId;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isLocaleInitialized = false;

  late AnimationController _mainAnimationController;
  late AnimationController _fabAnimationController;
  late AnimationController _filterAnimationController;

  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _filterAnimation;

  bool _hasExactAlarmPermission = false;

  bool _notificationsEnabled = true;
  int _reminderMinutes = 15;
  bool _exactTimeNotification = true;

  FilterType _currentFilter = FilterType.today;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static const Color primaryColor = Color(0xFF2196F3);
  static const Color primaryDarkColor = Color(0xFF1976D2);
  static const Color accentColor = Color(0xFFFF9800);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color cardColor = Colors.white;
  static const Color errorColor = Color(0xFFE57373);
  static const Color successColor = Color(0xFF66BB6A);
  static const Color textColor = Color(0xFF1A1A1A);
  static const Color textSecondaryColor = Color(0xFF64748B);
  static const Color shadowColor = Color(0x1A000000);

  String getTimeSlot(dynamic slot) {
    const timeSlots = [8, 9, 10, 11, 13, 14, 15, 16];
    if (slot is int && slot >= 1 && slot <= 8) {
      return '${timeSlots[slot - 1]}:00';
    }
    return 'Chưa xác định';
  }

  @override
  void initState() {
    super.initState();

    _mainAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _filterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: Curves.easeInOut,
    ));

    _filterAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _filterAnimationController,
      curve: Curves.easeInOut, // Changed from easeOutBack to avoid overshoot
    ));

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _initializeDateFormatting();
    await _initializeFirebase();
    await _initializeTimezone();
    await _initializeNotifications();
    _scheduleBackgroundFetch();
    await _loadNotificationSettings();
    await _loadDoctorIdAndFetch();
  }

  Future<void> _initializeDateFormatting() async {
    try {
      await initializeDateFormatting('vi', null);
      _isLocaleInitialized = true;
      print('Đã khởi tạo locale tiếng Việt thành công');
    } catch (e) {
      print('Lỗi khi khởi tạo locale: $e');
      _isLocaleInitialized = false;
    }
  }

  Future<void> _loadNotificationSettings() async {
    try {
      final notificationsEnabled = await _storage.read(key: 'notifications_enabled');
      final reminderMinutes = await _storage.read(key: 'reminder_minutes');
      final exactTimeNotification = await _storage.read(key: 'exact_time_notification');

      setState(() {
        _notificationsEnabled = notificationsEnabled != 'false';
        _reminderMinutes = int.tryParse(reminderMinutes ?? '15') ?? 15;
        _exactTimeNotification = exactTimeNotification != 'false';
      });

      print('Đã tải cài đặt thông báo: enabled=$_notificationsEnabled, minutes=$_reminderMinutes, exactTime=$_exactTimeNotification');
    } catch (e) {
      print('Lỗi khi tải cài đặt thông báo: $e');
    }
  }

  Future<void> _initializeFirebase() async {
    try {
      await Firebase.initializeApp();
      print('Firebase khởi tạo thành công');
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (message.notification != null) {
          print('Thông báo khi ứng dụng chạy: ${message.notification!.title}');
        }
      });
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      String? token = await messaging.getToken();
      if (token != null) {
        print('FCM Token: $token');
      } else {
        print('Không lấy được FCM Token');
      }
    } catch (e) {
      print('Lỗi khởi tạo Firebase: $e');
    }
  }

  Future<void> _initializeTimezone() async {
    tz.initializeTimeZones();
  }

  Future<void> _checkAndRequestPermissionsBasedOnVersion() async {
    if (!Platform.isAndroid) return;

    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final sdkVersion = androidInfo.version.sdkInt;

      print('Android SDK Version: $sdkVersion');

      if (sdkVersion >= 33) {
        final notificationStatus = await Permission.notification.status;
        if (!notificationStatus.isGranted) {
          await Permission.notification.request();
        }

        final exactAlarmStatus = await Permission.scheduleExactAlarm.status;
        if (!exactAlarmStatus.isGranted) {
          await Permission.scheduleExactAlarm.request();
        }

        _hasExactAlarmPermission = await Permission.scheduleExactAlarm.isGranted;

      } else if (sdkVersion >= 31) {
        final exactAlarmStatus = await Permission.scheduleExactAlarm.status;
        if (!exactAlarmStatus.isGranted) {
          await Permission.scheduleExactAlarm.request();
        }

        _hasExactAlarmPermission = await Permission.scheduleExactAlarm.isGranted;

      } else {
        _hasExactAlarmPermission = true;
      }

      print('Trạng thái quyền exact alarm: $_hasExactAlarmPermission');

    } catch (e) {
      print('Lỗi khi kiểm tra phiên bản và quyền: $e');
      _hasExactAlarmPermission = false;
    }
  }

  Future<void> _initializeNotifications() async {
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

    const AndroidNotificationChannel highImportanceChannel = AndroidNotificationChannel(
      'high_importance_channel',
      'Thông báo quan trọng',
      description: 'Thông báo lịch hẹn và nhắc nhở quan trọng',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      ledColor: Color.fromARGB(255, 255, 0, 0),
      showBadge: true,
    );

    const AndroidNotificationChannel nearTimeChannel = AndroidNotificationChannel(
      'appointment_near_time_channel',
      'Thông báo đã đến giờ khám',
      description: 'Thông báo 2 phút trước giờ khám với nội dung đã đến giờ',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      ledColor: Color.fromARGB(255, 0, 255, 0),
      showBadge: true,
    );

    final androidPlugin = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(highImportanceChannel);
      await androidPlugin.createNotificationChannel(nearTimeChannel);
      final granted = await androidPlugin.requestNotificationsPermission();
      print('Quyền thông báo Android: ${granted ?? false}');
    }

    await _checkAndRequestPermissionsBasedOnVersion();
  }

  Future<void> _scheduleNotification({
    required int id,
    required String patientName,
    required String timeSlot,
    required DateTime appointmentTime,
  }) async {
    if (!_notificationsEnabled) {
      print('Thông báo đã bị tắt, không lập lịch cho: $patientName');
      return;
    }

    try {
      final vietnamTimeZone = tz.getLocation('Asia/Ho_Chi_Minh');
      final currentTime = DateTime.now();

      final notificationTime = appointmentTime.subtract(Duration(minutes: _reminderMinutes));

      if (notificationTime.isBefore(currentTime)) {
        print('⚠️ Thời gian thông báo đã qua, không thể lập lịch cho: $patientName lúc $timeSlot');

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
        'appointment_channel_${_reminderMinutes}min',
        'Appointment Reminders ${_reminderMinutes}min',
        channelDescription: 'Notifications $_reminderMinutes minutes before appointments',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        playSound: true,
        enableVibration: true,
        styleInformation: BigTextStyleInformation(
          'Lịch hẹn với $patientName vào lúc $timeSlot chỉ còn $_reminderMinutes phút nữa! Hãy chuẩn bị sẵn sàng.',
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
        'Lịch hẹn sắp tới - $_reminderMinutes phút',
        'Lịch hẹn với $patientName vào lúc $timeSlot chỉ còn $_reminderMinutes phút nữa! Hãy chuẩn bị sẵn sàng.',
        tzScheduledTime,
        platformChannelSpecifics,
        androidScheduleMode: scheduleMode,
      );

      print('✅ Đã lập lịch thông báo ${_reminderMinutes}p cho: $patientName lúc $tzScheduledTime (ID $id)');

      if (_exactTimeNotification) {
        final nearTimeNotificationTime = appointmentTime.subtract(const Duration(minutes: 2));

        if (nearTimeNotificationTime.isAfter(currentTime)) {
          final nearTimeAndroidDetails = AndroidNotificationDetails(
            'appointment_near_time_channel',
            'Appointment Near Time',
            channelDescription: 'Notifications 2 minutes before appointment time',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
            playSound: true,
            enableVibration: true,
            enableLights: true,
            ledColor: Colors.green,
            ledOnMs: 1000,
            ledOffMs: 500,
            styleInformation: BigTextStyleInformation(
              'Đã đến giờ khám với $patientName! Lịch hẹn lúc $timeSlot đã bắt đầu.',
            ),
          );

          final nearTimePlatformSpecifics = NotificationDetails(
            android: nearTimeAndroidDetails,
          );

          final tzNearTime = tz.TZDateTime.from(
            nearTimeNotificationTime,
            vietnamTimeZone,
          );

          await _flutterLocalNotificationsPlugin.zonedSchedule(
            id + 10000,
            'Đã đến giờ khám!',
            'Đã đến giờ khám với $patientName! Lịch hẹn lúc $timeSlot đã bắt đầu.',
            tzNearTime,
            nearTimePlatformSpecifics,
            androidScheduleMode: scheduleMode,
          );

          print('✅ Đã lập lịch thông báo "đã đến giờ khám" (2p trước) cho: $patientName lúc $tzNearTime (ID ${id + 10000})');
        }
      }
    } catch (e) {
      print('❌ Lỗi khi lập lịch thông báo: $e');
    }
  }

  void _scheduleBackgroundFetch() {
    Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
    Workmanager().registerPeriodicTask(
      'fetch-appointments',
      fetchAppointmentsTask,
      frequency: Duration(minutes: 10),
      initialDelay: Duration(minutes: 2),
    );
  }

  @override
  void dispose() {
    _mainAnimationController.dispose();
    _fabAnimationController.dispose();
    _filterAnimationController.dispose();
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
        if (mounted) {
          _mainAnimationController.forward();
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              _filterAnimationController.forward();
            }
          });
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _fabAnimationController.forward();
            }
          });
        }
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
          appointments = jsonDecode(response.body) as List<dynamic>;
          _errorMessage = null;
        });
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

  void _scheduleNotificationsForToday() {
    if (!_notificationsEnabled) {
      print('Thông báo đã bị tắt, không lập lịch thông báo');
      return;
    }

    final now = tz.TZDateTime.now(tz.getLocation('Asia/Ho_Chi_Minh'));
    final todayStart = tz.TZDateTime(tz.getLocation('Asia/Ho_Chi_Minh'), now.year, now.month, now.day);
    final currentTime = DateTime.now();

    print('Kiểm tra lịch hẹn để lập thông báo vào: $now');
    for (var i = 0; i < appointments.length; i++) {
      final Map<String, dynamic> a = Map<String, dynamic>.from(appointments[i]);
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
        final parsedMedicalDay = DateTime.parse(medicalDay.toString());
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

            if (timeUntilAppointment.inMinutes > 0 && timeUntilAppointment.inMinutes <= (_reminderMinutes + 5)) {
              final patientList = a['patient'] as List<dynamic>?;
              final patientName = patientList != null && patientList.isNotEmpty
                  ? (patientList[0] as Map<String, dynamic>)['patient_name']?.toString() ?? 'Bệnh nhân ID: ${a['patient_id']}'
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

  String _formatDateVerbose(String? date) {
    if (date == null) return 'Chưa xác định';
    try {
      final parsedDate = DateTime.parse(date);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      final appointmentDate = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);

      if (appointmentDate.isAtSameMomentAs(today)) {
        return 'Hôm nay';
      } else if (appointmentDate.isAtSameMomentAs(tomorrow)) {
        return 'Ngày mai';
      } else {
        if (_isLocaleInitialized) {
          return DateFormat('EEEE, dd/MM/yyyy', 'vi').format(parsedDate);
        } else {
          return DateFormat('dd/MM/yyyy').format(parsedDate);
        }
      }
    } catch (e) {
      return date;
    }
  }

  List<dynamic> _getFilteredAppointments() {
    final now = tz.TZDateTime.now(tz.getLocation('Asia/Ho_Chi_Minh'));
    final todayStart = tz.TZDateTime(tz.getLocation('Asia/Ho_Chi_Minh'), now.year, now.month, now.day);
    final currentTime = DateTime.now();
    final currentHour = currentTime.hour;

    return appointments.where((appointment) {
      final Map<String, dynamic> a = Map<String, dynamic>.from(appointment);
      if (a['status'] != 'PENDING') return false;

      final medicalDay = a['medical_day'];
      if (medicalDay == null) return false;

      try {
        final parsedMedicalDay = DateTime.parse(medicalDay.toString());

        switch (_currentFilter) {
          case FilterType.today:
            if (!parsedMedicalDay.isAtSameMomentAs(todayStart)) {
              return false;
            }
            final slot = a['slot'];
            const timeSlots = [8, 9, 10, 11, 13, 14, 15, 16];
            if (slot is int && slot >= 1 && slot <= 8) {
              final appointmentHour = timeSlots[slot - 1];
              return appointmentHour > currentHour;
            }
            return false;

          case FilterType.thisMonth:
            if (parsedMedicalDay.isBefore(todayStart)) {
              return false;
            }
            if (parsedMedicalDay.year == now.year && parsedMedicalDay.month == now.month) {
              if (parsedMedicalDay.isAtSameMomentAs(todayStart)) {
                final slot = a['slot'];
                const timeSlots = [8, 9, 10, 11, 13, 14, 15, 16];
                if (slot is int && slot >= 1 && slot <= 8) {
                  final appointmentHour = timeSlots[slot - 1];
                  return appointmentHour > currentHour;
                }
                return false;
              }
              return true;
            }
            return false;

          case FilterType.thisYear:
            if (parsedMedicalDay.isBefore(todayStart)) {
              return false;
            }
            if (parsedMedicalDay.year == now.year) {
              if (parsedMedicalDay.isAtSameMomentAs(todayStart)) {
                final slot = a['slot'];
                const timeSlots = [8, 9, 10, 11, 13, 14, 15, 16];
                if (slot is int && slot >= 1 && slot <= 8) {
                  final appointmentHour = timeSlots[slot - 1];
                  return appointmentHour > currentHour;
                }
                return false;
              }
              return true;
            }
            return false;
        }
      } catch (e) {
        return false;
      }
    }).toList();
  }

  Widget _buildHeader() {
    return SizedBox(
      height: 180, // Keep the fixed height as per your design
      child: ClipRect(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryColor,
                  primaryDarkColor,
                ],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.calendar_today,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Lịch Khám Bệnh',
                              style: GoogleFonts.lora(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isLocaleInitialized
                                  ? DateFormat('EEEE, dd MMMM yyyy', 'vi').format(DateTime.now())
                                  : DateFormat('dd/MM/yyyy').format(DateTime.now()),
                              style: GoogleFonts.lora(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!_notificationsEnabled)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.notifications_off,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildStatsRow(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    final todayAppointments = _getFilteredAppointments().where((appointment) {
      final Map<String, dynamic> a = Map<String, dynamic>.from(appointment);
      final medicalDay = a['medical_day'];
      if (medicalDay == null) return false;
      try {
        final parsedDate = DateTime.parse(medicalDay.toString());
        final today = DateTime.now();
        return parsedDate.day == today.day &&
            parsedDate.month == today.month &&
            parsedDate.year == today.year;
      } catch (e) {
        return false;
      }
    }).length;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.today,
            label: 'Hôm nay',
            value: todayAppointments.toString(),
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 8), // Reduced from 12 to 8
        Expanded(
          child: _buildStatCard(
            icon: Icons.notifications_active,
            label: 'Thông báo',
            value: _notificationsEnabled ? 'BẬT' : 'TẮT',
            color: _notificationsEnabled ? successColor : errorColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(8), // Reduced from 12 to 8
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10), // Reduced from 12 to 10
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18), // Reduced from 20 to 18
          const SizedBox(height: 4), // Reduced from 6 to 4
          Text(
            value,
            style: GoogleFonts.lora(
              fontSize: 14, // Reduced from 16 to 14
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.lora(
              fontSize: 9, // Reduced from 10 to 9
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButtons() {
    return AnimatedBuilder(
      animation: _filterAnimation,
      builder: (context, child) {
        final clampedOpacity = math.min(1.0, math.max(0.0, _filterAnimation.value));
        return Transform.translate(
          offset: Offset(0, (1 - _filterAnimation.value) * 50),
          child: Opacity(
            opacity: clampedOpacity,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: _buildFilterButton(
                      'Hôm nay',
                      FilterType.today,
                      Icons.today_outlined,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildFilterButton(
                      'Tháng này',
                      FilterType.thisMonth,
                      Icons.calendar_month_outlined,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildFilterButton(
                      'Năm này',
                      FilterType.thisYear,
                      Icons.calendar_today_outlined,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterButton(String title, FilterType filterType, IconData icon) {
    final isSelected = _currentFilter == filterType;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: ElevatedButton.icon(
        onPressed: () {
          setState(() {
            _currentFilter = filterType;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? primaryColor : cardColor,
          foregroundColor: isSelected ? Colors.white : textColor,
          elevation: isSelected ? 4 : 1,
          shadowColor: isSelected ? primaryColor.withOpacity(0.3) : shadowColor,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? primaryColor : Colors.grey.shade300,
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
      ),
    );
  }

  Widget _buildAppointmentCard(Map<dynamic, dynamic> appointment, int index) {
    final Map<String, dynamic> appointmentData = Map<String, dynamic>.from(appointment);

    final patientList = appointmentData['patient'] as List<dynamic>?;
    final patientName = patientList != null && patientList.isNotEmpty
        ? (patientList[0] as Map<String, dynamic>)['patient_name']?.toString() ?? 'Bệnh nhân ID: ${appointmentData['patient_id']}'
        : 'Bệnh nhân ID: ${appointmentData['patient_id'] ?? 'Không xác định'}';

    final timeSlot = getTimeSlot(appointmentData['slot']);
    final appointmentDate = _formatDateVerbose(appointmentData['medical_day']?.toString());

    String timeUntilText = '';
    Color urgencyColor = primaryColor;

    try {
      final medicalDay = appointmentData['medical_day'];
      if (medicalDay != null) {
        final parsedDate = DateTime.parse(medicalDay.toString());
        final slot = appointmentData['slot'];
        const timeSlots = [8, 9, 10, 11, 13, 14, 15, 16];
        if (slot is int && slot >= 1 && slot <= 8) {
          final appointmentHour = timeSlots[slot - 1];
          final appointmentTime = DateTime(
            parsedDate.year,
            parsedDate.month,
            parsedDate.day,
            appointmentHour,
          );
          final now = DateTime.now();
          final difference = appointmentTime.difference(now);

          if (difference.inMinutes > 0) {
            if (difference.inHours < 1) {
              timeUntilText = 'Còn ${difference.inMinutes} phút';
              urgencyColor = errorColor;
            } else if (difference.inHours < 24) {
              timeUntilText = 'Còn ${difference.inHours} giờ';
              urgencyColor = accentColor;
            } else {
              timeUntilText = 'Còn ${difference.inDays} ngày';
              urgencyColor = successColor;
            }
          }
        }
      }
    } catch (e) {
      // Handle parsing error silently
    }

    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _fadeAnimation.value) * 30),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: Colors.grey.shade100,
                  width: 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            AppointmentDetailsScreen(appointment: appointmentData),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(1.0, 0.0),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            )),
                            child: child,
                          );
                        },
                        transitionDuration: const Duration(milliseconds: 300),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [primaryColor, primaryDarkColor],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
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
                                  const SizedBox(height: 4),
                                  Text(
                                    'ID: ${appointmentData['patient_id']}',
                                    style: GoogleFonts.lora(
                                      fontSize: 12,
                                      color: textSecondaryColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (timeUntilText.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: urgencyColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: urgencyColor.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  timeUntilText,
                                  style: GoogleFonts.lora(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: urgencyColor,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildInfoItem(
                                  Icons.calendar_today,
                                  'Ngày khám',
                                  appointmentDate,
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: Colors.grey.shade300,
                                margin: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                              Expanded(
                                child: _buildInfoItem(
                                  Icons.access_time,
                                  'Giờ khám',
                                  timeSlot,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: primaryColor,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.lora(
                  fontSize: 11,
                  color: textSecondaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.lora(
                  fontSize: 13,
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_busy_outlined,
              size: 64,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _getEmptyMessage(),
            style: GoogleFonts.lora(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Hãy kiểm tra lại sau hoặc thử bộ lọc khác',
            style: GoogleFonts.lora(
              fontSize: 14,
              color: textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: errorColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              size: 64,
              color: errorColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Có lỗi xảy ra',
            style: GoogleFonts.lora(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: GoogleFonts.lora(
              fontSize: 14,
              color: textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadDoctorIdAndFetch,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredAppointments = _getFilteredAppointments();

    filteredAppointments.sort((a, b) {
      final Map<String, dynamic> appointmentA = Map<String, dynamic>.from(a);
      final Map<String, dynamic> appointmentB = Map<String, dynamic>.from(b);

      final dateA = appointmentA['medical_day'] != null ? DateTime.parse(appointmentA['medical_day'].toString()) : DateTime(1970);
      final dateB = appointmentB['medical_day'] != null ? DateTime.parse(appointmentB['medical_day'].toString()) : DateTime(1970);
      final dateComparison = dateA.compareTo(dateB);
      if (dateComparison == 0) {
        final slotA = appointmentA['slot'] ?? 0;
        final slotB = appointmentB['slot'] ?? 0;
        return slotA.compareTo(slotB);
      }
      return dateComparison;
    });

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          // Constrain header height
          SizedBox(
            height: 170, // Adjust based on your design needs
            child: _buildHeader(),
          ),
          // Constrain filter buttons height
          SizedBox(
            height: 70, // Adjust based on your design needs
            child: _buildFilterButtons(),
          ),
          // Expanded to take remaining space
          Expanded(
            child: ClipRect(
              child: _isLoading
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: primaryColor,
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Đang tải lịch hẹn...',
                      style: GoogleFonts.lora(
                        fontSize: 16,
                        color: textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              )
                  : _errorMessage != null
                  ? _buildErrorState()
                  : filteredAppointments.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                onRefresh: () async {
                  await _loadNotificationSettings();
                  await fetchAppointments();
                },
                color: primaryColor,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredAppointments.length,
                  itemBuilder: (context, index) {
                    return _buildAppointmentCard(
                      filteredAppointments[index],
                      index,
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getEmptyMessage() {
    switch (_currentFilter) {
      case FilterType.today:
        return 'Không có lịch hẹn nào hôm nay';
      case FilterType.thisMonth:
        return 'Không có lịch hẹn nào tháng này';
      case FilterType.thisYear:
        return 'Không có lịch hẹn nào năm này';
    }
  }
}