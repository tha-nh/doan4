import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:workmanager/workmanager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';

// Hàm xử lý thông báo đẩy khi ứng dụng ở chế độ nền
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('📨 Background message: ${message.notification?.title}');

  // Trigger refresh appointments when receiving push notification
  if (message.data['action'] == 'refresh_appointments') {
    print('🔄 Triggering appointment refresh from background message');
    // Có thể trigger một background task để refresh
  }
}

// Định nghĩa task cho Workmanager
const String fetchAppointmentsTask = 'fetchAppointmentsTask';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print('🔄 Workmanager task $task started at: ${DateTime.now()}');
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
        print('🔕 Notifications disabled in settings');
        return Future.value(true);
      }

      if (idString != null) {
        final doctorId = int.tryParse(idString);
        if (doctorId != null) {
          final url = Uri.http('10.0.2.2:8081', '/api/v1/appointments/list', {
            'doctor_id': doctorId.toString(),
          });

          final response = await http.get(url);
          print('📡 Background API response: ${response.statusCode}');

          if (response.statusCode == 200) {
            final allAppointments = jsonDecode(response.body) as List<dynamic>;
            print('📅 Background fetched ${allAppointments.length} appointments');

            // Lọc ra các lịch hẹn cần thông báo ngay sau khi lấy dữ liệu
            final now = DateTime.now();
            final vietnamTimeZone = tz.getLocation('Asia/Ho_Chi_Minh');
            final filteredAppointments = _filterFutureAppointments(allAppointments, now);

            print('📅 Background filtered ${filteredAppointments.length} future appointments');

            // Khởi tạo notifications trong background
            const AndroidInitializationSettings initializationSettingsAndroid =
            AndroidInitializationSettings('@mipmap/ic_launcher');
            const InitializationSettings initializationSettings = InitializationSettings(
              android: initializationSettingsAndroid,
            );
            await FlutterLocalNotificationsPlugin().initialize(initializationSettings);

            int scheduledCount = 0;
            final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

            for (var i = 0; i < filteredAppointments.length; i++) {
              try {
                final Map<String, dynamic> a = filteredAppointments[i];
                final parsedMedicalDay = DateTime.parse(a['medical_day'].toString());
                final slot = a['slot'];
                const timeSlots = [8, 9, 10, 11, 13, 14, 15, 16];
                final appointmentHour = timeSlots[slot - 1];
                final appointmentTime = DateTime(
                  parsedMedicalDay.year,
                  parsedMedicalDay.month,
                  parsedMedicalDay.day,
                  appointmentHour,
                );

                final notificationTime = appointmentTime.subtract(Duration(minutes: reminderMinutesValue));

                // Check if notification time is valid
                if (notificationTime.isAfter(now)) {
                  final patientList = a['patient'] as List<dynamic>?;
                  final patientName = patientList != null && patientList.isNotEmpty
                      ? (patientList[0] as Map<String, dynamic>)['patient_name']?.toString() ?? 'Patient ID: ${a['patient_id']}'
                      : 'Patient ID: ${a['patient_id'] ?? 'Unknown'}';

                  // Sửa lỗi LED configuration
                  final androidDetails = AndroidNotificationDetails(
                    'appointment_channel_${reminderMinutesValue}min',
                    'Appointment Reminders ${reminderMinutesValue}min',
                    channelDescription: 'Notifications $reminderMinutesValue minutes before appointments',
                    importance: Importance.max,
                    priority: Priority.high,
                    showWhen: true,
                    playSound: true,
                    enableVibration: true,
                    // Bỏ enableLights và ledColor để tránh lỗi trên các thiết bị cũ
                    styleInformation: BigTextStyleInformation(
                      'Lịch hẹn với $patientName vào lúc ${'$appointmentHour:00'} chỉ còn $reminderMinutesValue phút nữa!',
                    ),
                  );

                  final platformChannelSpecifics = NotificationDetails(android: androidDetails);
                  final tzScheduledTime = tz.TZDateTime.from(notificationTime, vietnamTimeZone);

                  if (tzScheduledTime.isAfter(tz.TZDateTime.now(vietnamTimeZone))) {
                    await flutterLocalNotificationsPlugin.zonedSchedule(
                      i + 50000, // Offset để tránh conflict với main app
                      'Lịch hẹn sắp tới - $reminderMinutesValue phút',
                      'Lịch hẹn với $patientName vào lúc ${'$appointmentHour:00'} chỉ còn $reminderMinutesValue phút nữa!',
                      tzScheduledTime,
                      platformChannelSpecifics,
                      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
                    );

                    scheduledCount++;
                    print('✅ Background scheduled notification for: $patientName at $tzScheduledTime');

                    // Schedule exact time notification if enabled
                    if (isExactTimeEnabled) {
                      final nearTimeNotificationTime = appointmentTime.subtract(const Duration(minutes: 2));
                      if (nearTimeNotificationTime.isAfter(now)) {
                        // Sửa lỗi LED configuration
                        final nearTimeDetails = AndroidNotificationDetails(
                          'appointment_near_time_channel',
                          'Appointment Near Time',
                          channelDescription: 'Notifications 2 minutes before appointment time',
                          importance: Importance.max,
                          priority: Priority.high,
                          showWhen: true,
                          playSound: true,
                          enableVibration: true,
                          // Bỏ enableLights và ledColor để tránh lỗi trên các thiết bị cũ
                          styleInformation: BigTextStyleInformation(
                            'Đã đến giờ khám với $patientName! Lịch hẹn lúc ${'$appointmentHour:00'} đã bắt đầu.',
                          ),
                        );

                        final nearTimePlatformSpecifics = NotificationDetails(android: nearTimeDetails);
                        final tzNearTime = tz.TZDateTime.from(nearTimeNotificationTime, vietnamTimeZone);

                        if (tzNearTime.isAfter(tz.TZDateTime.now(vietnamTimeZone))) {
                          await flutterLocalNotificationsPlugin.zonedSchedule(
                            i + 60000, // Offset khác để tránh conflict
                            'Đã đến giờ khám!',
                            'Đã đến giờ khám với $patientName! Lịch hẹn lúc ${'$appointmentHour:00'} đã bắt đầu.',
                            tzNearTime,
                            nearTimePlatformSpecifics,
                            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
                          );

                          scheduledCount++;
                          print('✅ Background scheduled near-time notification for: $patientName');
                        }
                      }
                    }
                  }
                } else {
                  print('⚠️ Background: Notification time passed for appointment at $appointmentTime');
                }
              } catch (e) {
                print('❌ Background error processing appointment $i: $e');
                // Tiếp tục xử lý các lịch hẹn khác ngay cả khi có lỗi
                continue;
              }
            }

            print('📊 Background scheduled $scheduledCount notifications');
          } else {
            print('❌ Background API error: ${response.statusCode}');
          }
        }
      }
    } catch (e) {
      print('❌ Background Workmanager error: $e');
    }
    return Future.value(true);
  });
}

// Hàm lọc lịch hẹn trong tương lai và có trạng thái PENDING
List<Map<String, dynamic>> _filterFutureAppointments(List<dynamic> appointments, DateTime now) {
  final result = <Map<String, dynamic>>[];
  const timeSlots = [8, 9, 10, 11, 13, 14, 15, 16];

  for (var appointment in appointments) {
    try {
      final Map<String, dynamic> a = Map<String, dynamic>.from(appointment);

      // Kiểm tra trạng thái
      if (a['status'] != 'PENDING') continue;

      // Kiểm tra ngày khám
      final medicalDay = a['medical_day'];
      if (medicalDay == null) continue;

      // Parse ngày và giờ khám
      final parsedMedicalDay = DateTime.parse(medicalDay.toString());
      final slot = a['slot'];

      if (slot is int && slot >= 1 && slot <= 8) {
        final appointmentHour = timeSlots[slot - 1];
        final appointmentTime = DateTime(
          parsedMedicalDay.year,
          parsedMedicalDay.month,
          parsedMedicalDay.day,
          appointmentHour,
        );

        // Chỉ lấy các lịch hẹn trong tương lai
        if (appointmentTime.isAfter(now)) {
          result.add(a);
        }
      }
    } catch (e) {
      print('❌ Error filtering appointment: $e');
    }
  }

  return result;
}

class AppointmentService {
  static final AppointmentService _instance = AppointmentService._internal();
  factory AppointmentService() => _instance;
  AppointmentService._internal();

  final _storage = const FlutterSecureStorage();
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  bool _hasExactAlarmPermission = false;
  bool _notificationsEnabled = true;
  int _reminderMinutes = 15;
  bool _exactTimeNotification = true;
  bool _isBasicInitialized = false;
  bool _isUserInitialized = false;

  // Getters
  bool get notificationsEnabled => _notificationsEnabled;
  int get reminderMinutes => _reminderMinutes;
  bool get exactTimeNotification => _exactTimeNotification;
  bool get isBasicInitialized => _isBasicInitialized;
  bool get isUserInitialized => _isUserInitialized;

  // PHASE 1: Khởi tạo services cơ bản (TRƯỚC LOGIN)
  Future<void> initializeBasicServices() async {
    if (_isBasicInitialized) {
      print('⚠️ Basic services đã được khởi tạo rồi');
      return;
    }

    try {
      print('🔧 Khởi tạo Firebase...');
      await _initializeFirebase();

      print('🔧 Khởi tạo Timezone...');
      await _initializeTimezone();

      print('🔧 Khởi tạo Date Formatting...');
      await _initializeDateFormatting();

      print('🔧 Khởi tạo Notifications...');
      await _initializeNotifications();

      print('🔧 Load Notification Settings...');
      await loadNotificationSettings();

      _isBasicInitialized = true;
      print('✅ Phase 1: Basic services hoàn tất');

    } catch (e) {
      print('❌ Lỗi Phase 1: $e');
      throw e;
    }
  }

  // PHASE 2: Khởi tạo services cần doctor_id (SAU LOGIN)
  Future<void> initializeUserServices(int doctorId) async {
    if (!_isBasicInitialized) {
      throw Exception('Basic services chưa được khởi tạo');
    }

    if (_isUserInitialized) {
      print('⚠️ User services đã được khởi tạo rồi');
      return;
    }

    try {
      print('🔧 Khởi tạo Background Tasks...');
      await _scheduleBackgroundFetch();

      print('🔧 Setup Firebase messaging for real-time updates...');
      await _setupFirebaseMessaging(doctorId);

      print('🔧 Fetch và schedule notifications cho doctor $doctorId...');
      final appointments = await fetchAppointments(doctorId);
      await scheduleNotificationsForToday(appointments);

      _isUserInitialized = true;
      print('✅ Phase 2: User services hoàn tất cho doctor $doctorId');

    } catch (e) {
      print('❌ Lỗi Phase 2: $e');
      // Không throw error để app vẫn hoạt động
    }
  }

  // Setup Firebase messaging cho real-time updates
  Future<void> _setupFirebaseMessaging(int doctorId) async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;

      // Subscribe to doctor-specific topic
      await messaging.subscribeToTopic('doctor_$doctorId');
      print('📡 Subscribed to topic: doctor_$doctorId');

      // Subscribe to general appointments topic
      await messaging.subscribeToTopic('appointments_update');
      print('📡 Subscribed to topic: appointments_update');

      // Listen for foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        print('📨 Foreground message received: ${message.notification?.title}');

        if (message.data['action'] == 'refresh_appointments') {
          print('🔄 Refreshing appointments due to push notification');
          try {
            final appointments = await fetchAppointments(doctorId);
            await scheduleNotificationsForToday(appointments);
            print('✅ Appointments refreshed successfully');
          } catch (e) {
            print('❌ Error refreshing appointments: $e');
          }
        }

        // Show local notification
        if (message.notification != null) {
          await _flutterLocalNotificationsPlugin.show(
            message.hashCode,
            message.notification!.title,
            message.notification!.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                'high_importance_channel',
                'Thông báo quan trọng',
                channelDescription: 'Thông báo lịch hẹn và nhắc nhở quan trọng',
                importance: Importance.max,
                priority: Priority.high,
              ),
            ),
          );
        }
      });

    } catch (e) {
      print('❌ Firebase messaging setup error: $e');
    }
  }

  // Backward compatibility - sử dụng cả 2 phases
  Future<void> initializeService() async {
    await initializeBasicServices();
    // User services sẽ được khởi tạo sau khi login
  }

  Future<void> _initializeDateFormatting() async {
    try {
      await initializeDateFormatting('vi', null);
      print('✅ Locale tiếng Việt đã sẵn sàng');
    } catch (e) {
      print('❌ Lỗi locale: $e');
    }
  }

  Future<void> loadNotificationSettings() async {
    try {
      final notificationsEnabled = await _storage.read(key: 'notifications_enabled');
      final reminderMinutes = await _storage.read(key: 'reminder_minutes');
      final exactTimeNotification = await _storage.read(key: 'exact_time_notification');

      _notificationsEnabled = notificationsEnabled != 'false';
      _reminderMinutes = int.tryParse(reminderMinutes ?? '15') ?? 15;
      _exactTimeNotification = exactTimeNotification != 'false';

      print('📱 Settings: notifications=$_notificationsEnabled, minutes=$_reminderMinutes, exactTime=$_exactTimeNotification');
    } catch (e) {
      print('❌ Lỗi load settings: $e');
    }
  }

  Future<void> _initializeFirebase() async {
    try {
      await Firebase.initializeApp();
      print('✅ Firebase sẵn sàng');

      FirebaseMessaging messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();

      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      String? token = await messaging.getToken();
      if (token != null) {
        print('🔑 FCM Token: ${token.substring(0, 20)}...');
      }
    } catch (e) {
      print('❌ Firebase error: $e');
      throw e;
    }
  }

  Future<void> _initializeTimezone() async {
    tz.initializeTimeZones();
    print('✅ Timezone sẵn sàng');
  }

  Future<void> _checkAndRequestPermissionsBasedOnVersion() async {
    if (!Platform.isAndroid) return;

    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final sdkVersion = androidInfo.version.sdkInt;

      print('📱 Android SDK: $sdkVersion');

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

      print('🔐 Exact alarm permission: $_hasExactAlarmPermission');

    } catch (e) {
      print('❌ Permission error: $e');
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
        print('👆 Notification tapped: ${response.payload}');
      },
    );

    const AndroidNotificationChannel highImportanceChannel = AndroidNotificationChannel(
      'high_importance_channel',
      'Thông báo quan trọng',
      description: 'Thông báo lịch hẹn và nhắc nhở quan trọng',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      // Bỏ enableLights và ledColor để tránh lỗi trên các thiết bị cũ
    );

    const AndroidNotificationChannel nearTimeChannel = AndroidNotificationChannel(
      'appointment_near_time_channel',
      'Thông báo đã đến giờ khám',
      description: 'Thông báo khi đã đến giờ',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      // Bỏ enableLights và ledColor để tránh lỗi trên các thiết bị cũ
    );

    final androidPlugin = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(highImportanceChannel);
      await androidPlugin.createNotificationChannel(nearTimeChannel);
      final granted = await androidPlugin.requestNotificationsPermission();
      print('🔔 Notification permission: ${granted ?? false}');
    }

    await _checkAndRequestPermissionsBasedOnVersion();
    print('✅ Notifications sẵn sàng');
  }

  Future<void> scheduleNotification({
    required int id,
    required String patientName,
    required String timeSlot,
    required DateTime appointmentTime,
  }) async {
    if (!_notificationsEnabled) {
      print('🔕 Notifications disabled for: $patientName');
      return;
    }

    try {
      final vietnamTimeZone = tz.getLocation('Asia/Ho_Chi_Minh');
      final currentTime = DateTime.now();

      final notificationTime = appointmentTime.subtract(Duration(minutes: _reminderMinutes));

      // Kiểm tra thời gian thông báo có hợp lệ không
      if (notificationTime.isBefore(currentTime) || notificationTime.isAtSameMomentAs(currentTime)) {
        print('⚠️ Notification time passed or invalid for: $patientName at $timeSlot');

        // Nếu appointment vẫn trong tương lai và còn ít nhất 1 phút
        if (appointmentTime.isAfter(currentTime) &&
            appointmentTime.difference(currentTime).inMinutes >= 1) {
          print('🔄 Showing immediate notification');

          final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
            'appointment_immediate_channel',
            'Immediate Appointment Reminders',
            channelDescription: 'Immediate notifications for upcoming appointments',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
            playSound: true,
            enableVibration: true,
            // Bỏ enableLights và ledColor để tránh lỗi trên các thiết bị cũ
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

          print('✅ Immediate notification shown for: $patientName at $timeSlot');
        }
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
        // Bỏ enableLights và ledColor để tránh lỗi trên các thiết bị cũ
      );

      final NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidDetails,
      );

      final tzScheduledTime = tz.TZDateTime.from(
        notificationTime,
        vietnamTimeZone,
      );

      // Kiểm tra lại lần nữa trước khi schedule
      if (tzScheduledTime.isBefore(tz.TZDateTime.now(vietnamTimeZone))) {
        print('⚠️ TZDateTime is in the past, skipping: $tzScheduledTime');
        return;
      }

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

      print('✅ Scheduled ${_reminderMinutes}min notification for: $patientName at $tzScheduledTime (ID $id)');

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
            // Bỏ enableLights và ledColor để tránh lỗi trên các thiết bị cũ
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

          // Kiểm tra thời gian near-time notification
          if (tzNearTime.isAfter(tz.TZDateTime.now(vietnamTimeZone))) {
            await _flutterLocalNotificationsPlugin.zonedSchedule(
              id + 10000,
              'Đã đến giờ khám!',
              'Đã đến giờ khám với $patientName! Lịch hẹn lúc $timeSlot đã bắt đầu.',
              tzNearTime,
              nearTimePlatformSpecifics,
              androidScheduleMode: scheduleMode,
            );

            print('✅ Scheduled "time to examine" notification (2min before) for: $patientName at $tzNearTime (ID ${id + 10000})');
          }
        }
      }
    } catch (e) {
      print('❌ Notification scheduling error: $e');
    }
  }

  Future<void> _scheduleBackgroundFetch() async {
    try {
      Workmanager().initialize(callbackDispatcher, isInDebugMode: true);

      // Periodic task với frequency tối thiểu 15 phút
      Workmanager().registerPeriodicTask(
        'fetch-appointments-periodic',
        fetchAppointmentsTask,
        frequency: Duration(minutes: 15), // Minimum allowed by Android
        initialDelay: Duration(minutes: 1),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
      );

      // One-off task để test ngay
      Workmanager().registerOneOffTask(
        'fetch-appointments-immediate',
        fetchAppointmentsTask,
        initialDelay: Duration(seconds: 30),
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );

      print('✅ Background tasks scheduled (15min periodic + immediate test)');
    } catch (e) {
      print('❌ Background task scheduling error: $e');
    }
  }

  // Fetch và lọc appointments trong một lần gọi
  Future<List<Map<String, dynamic>>> fetchAppointments(int doctorId) async {
    final url = Uri.http('10.0.2.2:8081', '/api/v1/appointments/list', {
      'doctor_id': doctorId.toString(),
    });

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final allAppointments = jsonDecode(response.body) as List<dynamic>;
        print('📅 Fetched ${allAppointments.length} total appointments for doctor $doctorId');

        // Lọc ngay sau khi lấy dữ liệu
        final now = DateTime.now();
        final filteredAppointments = _filterFutureAppointments(allAppointments, now);

        print('📅 Filtered to ${filteredAppointments.length} future appointments');

        // Sắp xếp theo thời gian
        filteredAppointments.sort((a, b) {
          final dateA = DateTime.parse(a['medical_day'].toString());
          final dateB = DateTime.parse(b['medical_day'].toString());
          final dateComparison = dateA.compareTo(dateB);

          if (dateComparison == 0) {
            final slotA = a['slot'] ?? 0;
            final slotB = b['slot'] ?? 0;
            return slotA.compareTo(slotB);
          }

          return dateComparison;
        });

        return filteredAppointments;
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Fetch appointments error: $e');
      throw Exception('Connection error. Please try again!');
    }
  }

  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
    print('🗑️ All notifications cancelled');
  }

  Future<void> scheduleNotificationsForToday(List<Map<String, dynamic>> filteredAppointments) async {
    if (!_notificationsEnabled) {
      print('🔕 Notifications disabled, skipping scheduling');
      return;
    }

    await cancelAllNotifications();
    final now = DateTime.now();

    print('📅 Scheduling notifications for ${filteredAppointments.length} appointments');

    int scheduledCount = 0;
    const timeSlots = [8, 9, 10, 11, 13, 14, 15, 16];

    for (var i = 0; i < filteredAppointments.length; i++) {
      try {
        final a = filteredAppointments[i];
        final parsedMedicalDay = DateTime.parse(a['medical_day'].toString());
        final slot = a['slot'];

        if (slot is int && slot >= 1 && slot <= 8) {
          final appointmentHour = timeSlots[slot - 1];
          final appointmentTime = DateTime(
            parsedMedicalDay.year,
            parsedMedicalDay.month,
            parsedMedicalDay.day,
            appointmentHour,
          );

          final patientList = a['patient'] as List<dynamic>?;
          final patientName = patientList != null && patientList.isNotEmpty
              ? (patientList[0] as Map<String, dynamic>)['patient_name']?.toString() ?? 'Patient ID: ${a['patient_id']}'
              : 'Patient ID: ${a['patient_id'] ?? 'Unknown'}';

          await scheduleNotification(
            id: i,
            patientName: patientName,
            timeSlot: getTimeSlot(slot),
            appointmentTime: appointmentTime,
          );

          scheduledCount++;
        }
      } catch (e) {
        print('❌ Error scheduling notification for appointment $i: $e');
      }
    }

    // Check scheduled notifications
    final pendingNotifications = await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
    print('📊 Scheduled $scheduledCount notifications, pending: ${pendingNotifications.length}');
  }

  String getTimeSlot(dynamic slot) {
    const timeSlots = [8, 9, 10, 11, 13, 14, 15, 16];
    if (slot is int && slot >= 1 && slot <= 8) {
      return '${timeSlots[slot - 1]}:00';
    }
    return 'Not specified';
  }

  // Method để refresh appointments manually
  Future<void> refreshAppointments(int doctorId) async {
    try {
      print('🔄 Manual refresh appointments for doctor $doctorId');
      final appointments = await fetchAppointments(doctorId);
      await scheduleNotificationsForToday(appointments);
      print('✅ Manual refresh completed');
    } catch (e) {
      print('❌ Manual refresh error: $e');
      throw e;
    }
  }
}
