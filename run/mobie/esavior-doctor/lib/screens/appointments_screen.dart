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
import 'appointment_details_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';

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

                    // Thông báo trước 15 phút
                    if (timeUntilAppointment.inMinutes > 0 && timeUntilAppointment.inMinutes <= 20) {
                      print('Lập lịch thông báo 15p cho: $patientName, thời gian: $appointmentTime');

                      final androidPlatformChannelSpecifics = AndroidNotificationDetails(
                        'appointment_channel_15min',
                        'Appointment Reminders 15min',
                        channelDescription: 'Notifications 15 minutes before appointments',
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
                          'Lịch hẹn với $patientName vào lúc ${'$appointmentHour:00'} chỉ còn 15 phút nữa! Hãy chuẩn bị sẵn sàng.',
                        ),
                      );

                      final platformChannelSpecifics = NotificationDetails(
                        android: androidPlatformChannelSpecifics,
                      );

                      await flutterLocalNotificationsPlugin.zonedSchedule(
                        i,
                        'Lịch hẹn sắp tới - 15 phút',
                        'Lịch hẹn với $patientName vào lúc ${'$appointmentHour:00'} chỉ còn 15 phút nữa! Hãy chuẩn bị sẵn sàng.',
                        tz.TZDateTime.from(appointmentTime.subtract(Duration(minutes: 15)), vietnamTimeZone),
                        platformChannelSpecifics,
                        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
                      );
                      print('Thông báo 15p đã được lập lịch cho ID: $i');

                      // Thông báo 2 phút trước giờ hẹn với nội dung "Đã đến giờ khám"
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
                        i + 10000, // Sử dụng ID khác để tránh trùng lặp
                        'Đã đến giờ khám!',
                        'Đã đến giờ khám với $patientName! Lịch hẹn lúc ${'$appointmentHour:00'} đã bắt đầu.',
                        tz.TZDateTime.from(appointmentTime.subtract(Duration(minutes: 2)), vietnamTimeZone), // 2 phút trước
                        nearTimePlatformSpecifics,
                        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
                      );
                      print('Thông báo "đã đến giờ khám" (2p trước) đã được lập lịch cho ID: ${i + 10000}');
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

  FilterType _currentFilter = FilterType.today;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  String getTimeSlot(dynamic slot) {
    const timeSlots = [8, 9, 10, 11, 13, 14, 15, 16];
    if (slot is int && slot >= 1 && slot <= 8) {
      return '${timeSlots[slot - 1]}:00';
    }
    return 'Chưa xác định';
  }

  // Color palette
  static const Color primaryColor = Color(0xFF0288D1);
  static const Color accentColor = Color(0xFFFFB300);
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color cardColor = Colors.white;
  static const Color errorColor = Color(0xFFE57373);
  static const Color textColor = Color(0xFF1A1A1A);

  @override
  void initState() {
    super.initState();
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

    _initializeFirebase();
    _initializeTimezone();
    _initializeNotifications();
    _scheduleBackgroundFetch();

    if (mounted) {
      _animationController.forward();
    }
    _loadDoctorIdAndFetch();
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

    // Tạo kênh thông báo cho thông báo "đã đến giờ khám" (2 phút trước)
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
    try {
      final vietnamTimeZone = tz.getLocation('Asia/Ho_Chi_Minh');
      final currentTime = DateTime.now();

      // Thông báo trước 15 phút
      final notificationTime = appointmentTime.subtract(const Duration(minutes: 15));

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

      // Thông báo trước 15 phút
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
        'Lịch hẹn sắp tới - 15 phút',
        'Lịch hẹn với $patientName vào lúc $timeSlot chỉ còn 15 phút nữa! Hãy chuẩn bị sẵn sàng.',
        tzScheduledTime,
        platformChannelSpecifics,
        androidScheduleMode: scheduleMode,
      );

      print('✅ Đã lập lịch thông báo 15p cho: $patientName lúc $tzScheduledTime (ID $id)');

      // Thông báo 2 phút trước giờ hẹn với nội dung "Đã đến giờ khám"
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
          id + 10000, // Sử dụng ID khác để tránh trùng lặp
          'Đã đến giờ khám!',
          'Đã đến giờ khám với $patientName! Lịch hẹn lúc $timeSlot đã bắt đầu.',
          tzNearTime,
          nearTimePlatformSpecifics,
          androidScheduleMode: scheduleMode,
        );

        print('✅ Đã lập lịch thông báo "đã đến giờ khám" (2p trước) cho: $patientName lúc $tzNearTime (ID ${id + 10000})');
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


  @override
  Widget build(BuildContext context) {
    final filteredAppointments = _getFilteredAppointments();

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
          ],
        ),
      ),
    );
  }

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