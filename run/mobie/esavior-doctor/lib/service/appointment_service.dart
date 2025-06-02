import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:workmanager/workmanager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';
import 'notification_id_manager.dart';
import 'notification_cache_manager.dart';

// Optimized background task
const String fetchAppointmentsTask = 'fetchAppointmentsTask';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print('🔄 Background task started: $task');

    try {
      tz.initializeTimeZones();
      await initializeDateFormatting('vi', null);

      final storage = FlutterSecureStorage();

      // Load settings
      final notificationsEnabled = await storage.read(key: 'notifications_enabled');
      if (notificationsEnabled == 'false') {
        print('🔕 Notifications disabled, skipping background task');
        return Future.value(true);
      }

      final doctorIdString = await storage.read(key: 'doctor_id');
      if (doctorIdString == null) {
        print('❌ No doctor ID found');
        return Future.value(true);
      }

      final doctorId = int.tryParse(doctorIdString);
      if (doctorId == null) {
        print('❌ Invalid doctor ID');
        return Future.value(true);
      }

      // Fetch appointments with retry
      final appointments = await _fetchAppointmentsWithRetry(doctorId);
      if (appointments.isEmpty) {
        print('⚠️ No appointments fetched');
        return Future.value(true);
      }

      // Schedule notifications
      await _scheduleBackgroundNotifications(appointments, storage);

      print('✅ Background task completed successfully');
      return Future.value(true);

    } catch (e) {
      print('❌ Background task error: $e');
      return Future.value(false);
    }
  });
}

Future<List<Map<String, dynamic>>> _fetchAppointmentsWithRetry(int doctorId) async {
  const maxRetries = 3;
  const retryDelay = Duration(seconds: 5);

  for (int attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      final url = Uri.http('10.0.2.2:8081', '/api/v1/appointments/list', {
        'doctor_id': doctorId.toString(),
      });

      final response = await http.get(url).timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        final allAppointments = jsonDecode(response.body) as List<dynamic>;
        final filteredAppointments = _filterFutureAppointments(allAppointments);

        // Cache successful result
        await NotificationCacheManager.cacheAppointments(filteredAppointments);

        return filteredAppointments;
      }
    } catch (e) {
      print('❌ Fetch attempt $attempt failed: $e');

      if (attempt == maxRetries) {
        // Last attempt - try cache
        final cached = await NotificationCacheManager.getCachedAppointments();
        return cached ?? [];
      }

      await Future.delayed(retryDelay * attempt);
    }
  }

  return [];
}

Future<void> _scheduleBackgroundNotifications(
    List<Map<String, dynamic>> appointments,
    FlutterSecureStorage storage,
    ) async {
  try {
    // Load settings
    final reminderMinutes = int.tryParse(await storage.read(key: 'reminder_minutes') ?? '15') ?? 15;
    final exactTimeNotification = await storage.read(key: 'exact_time_notification') != 'false';

    // Initialize notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    final vietnamTimeZone = tz.getLocation('Asia/Ho_Chi_Minh');
    final now = DateTime.now();

    // Get the start and end of today
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(Duration(days: 1));

    int scheduledCount = 0;
    List<int> scheduledIds = [];

    for (int i = 0; i < appointments.length && i < 50; i++) { // Limit to 50
      try {
        final appointment = appointments[i];
        final appointmentTime = _getAppointmentDateTime(appointment);

        if (!appointmentTime.isAfter(now)) continue;

        // Only schedule notifications for today's appointments
        if (!appointmentTime.isBefore(tomorrow)) continue;

        final patientName = _getPatientName(appointment);
        final timeSlot = _getTimeSlot(appointment['slot']);

        // Schedule reminder notification
        final reminderTime = appointmentTime.subtract(Duration(minutes: reminderMinutes));
        if (reminderTime.isAfter(now)) {
          final reminderId = NotificationIdManager.generateBackgroundId(i);

          await _scheduleNotification(
            flutterLocalNotificationsPlugin,
            id: reminderId,
            title: 'Lịch hẹn sắp tới - $reminderMinutes phút',
            body: 'Lịch hẹn với $patientName vào lúc $timeSlot chỉ còn $reminderMinutes phút nữa!',
            scheduledTime: reminderTime,
            vietnamTimeZone: vietnamTimeZone,
          );

          scheduledIds.add(reminderId);
          scheduledCount++;
        }

        // Schedule exact time notification
        if (exactTimeNotification) {
          final exactTime = appointmentTime.subtract(Duration(minutes: 2));
          if (exactTime.isAfter(now)) {
            final exactId = NotificationIdManager.generateBackgroundId(i + 1000);

            await _scheduleNotification(
              flutterLocalNotificationsPlugin,
              id: exactId,
              title: 'Đã đến giờ khám!',
              body: 'Đã đến giờ khám với $patientName! Lịch hẹn lúc $timeSlot đã bắt đầu.',
              scheduledTime: exactTime,
              vietnamTimeZone: vietnamTimeZone,
            );

            scheduledIds.add(exactId);
            scheduledCount++;
          }
        }
      } catch (e) {
        print('❌ Error scheduling background notification $i: $e');
        continue;
      }
    }

    // Cache scheduled notification IDs
    await NotificationCacheManager.cacheScheduledNotifications(scheduledIds);

    print('📊 Background scheduled $scheduledCount notifications for today');
  } catch (e) {
    print('❌ Background notification scheduling error: $e');
  }
}

Future<void> _scheduleNotification(
    FlutterLocalNotificationsPlugin plugin, {
      required int id,
      required String title,
      required String body,
      required DateTime scheduledTime,
      required tz.Location vietnamTimeZone,
    }) async {
  final androidDetails = AndroidNotificationDetails(
    'appointment_background_channel',
    'Background Appointment Notifications',
    channelDescription: 'Background notifications for appointments',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: true,
    playSound: true,
    enableVibration: true,
  );

  final platformChannelSpecifics = NotificationDetails(android: androidDetails);
  final tzScheduledTime = tz.TZDateTime.from(scheduledTime, vietnamTimeZone);

  if (tzScheduledTime.isAfter(tz.TZDateTime.now(vietnamTimeZone))) {
    await plugin.zonedSchedule(
      id,
      title,
      body,
      tzScheduledTime,
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}

// Modified to filter all future appointments
List<Map<String, dynamic>> _filterFutureAppointments(List<dynamic> appointments) {
  final result = <Map<String, dynamic>>[];
  final now = DateTime.now();

  for (var appointment in appointments) {
    try {
      final Map<String, dynamic> a = Map<String, dynamic>.from(appointment);

      if (a['status'] != 'PENDING') continue;

      final appointmentTime = _getAppointmentDateTime(a);

      // Include all future appointments
      if (appointmentTime.isAfter(now)) {
        result.add(a);
      }
    } catch (e) {
      print('❌ Error filtering appointment: $e');
    }
  }

  return result;
}

DateTime _getAppointmentDateTime(Map<String, dynamic> appointment) {
  final medicalDay = DateTime.parse(appointment['medical_day'].toString());
  final slot = appointment['slot'] as int;
  const timeSlots = [8, 9, 10, 11, 13, 14, 15, 16];
  final appointmentHour = timeSlots[slot - 1];

  return DateTime(
    medicalDay.year,
    medicalDay.month,
    medicalDay.day,
    appointmentHour,
  );
}

String _getPatientName(Map<String, dynamic> appointment) {
  final patientList = appointment['patient'] as List<dynamic>?;
  if (patientList != null && patientList.isNotEmpty) {
    return (patientList[0] as Map<String, dynamic>)['patient_name']?.toString()
        ?? 'Patient ID: ${appointment['patient_id']}';
  }
  return 'Patient ID: ${appointment['patient_id'] ?? 'Unknown'}';
}

String _getTimeSlot(dynamic slot) {
  const timeSlots = [8, 9, 10, 11, 13, 14, 15, 16];
  if (slot is int && slot >= 1 && slot <= 8) {
    return '${timeSlots[slot - 1]}:00';
  }
  return 'Not specified';
}

class OptimizedAppointmentService {
  static final OptimizedAppointmentService _instance = OptimizedAppointmentService._internal();
  factory OptimizedAppointmentService() => _instance;
  OptimizedAppointmentService._internal();

  final _storage = const FlutterSecureStorage();
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // Settings
  bool _notificationsEnabled = true;
  int _reminderMinutes = 15;
  bool _exactTimeNotification = true;
  bool _hasExactAlarmPermission = false;

  // State
  bool _isBasicInitialized = false;
  bool _isUserInitialized = false;
  DateTime? _lastFetchTime;

  // Getters
  bool get notificationsEnabled => _notificationsEnabled;
  int get reminderMinutes => _reminderMinutes;
  bool get exactTimeNotification => _exactTimeNotification;
  bool get isBasicInitialized => _isBasicInitialized;
  bool get isUserInitialized => _isUserInitialized;

  // PHASE 1: Basic Services Initialization
  Future<void> initializeBasicServices() async {
    if (_isBasicInitialized) {
      print('⚠️ Basic services already initialized');
      return;
    }

    try {
      print('🔧 Initializing Timezone...');
      await _initializeTimezone();

      print('🔧 Initializing Date Formatting...');
      await _initializeDateFormatting();

      print('🔧 Initializing Notifications...');
      await _initializeNotifications();

      print('🔧 Loading Notification Settings...');
      await loadNotificationSettings();

      _isBasicInitialized = true;
      print('✅ Phase 1: Basic services completed');

    } catch (e) {
      print('❌ Phase 1 error: $e');
      throw e;
    }
  }

  // PHASE 2: User Services Initialization
  Future<void> initializeUserServices(int doctorId) async {
    if (!_isBasicInitialized) {
      throw Exception('Basic services not initialized');
    }

    if (_isUserInitialized) {
      print('⚠️ User services already initialized');
      return;
    }

    try {
      print('🔧 Scheduling optimized background tasks...');
      await _scheduleOptimizedBackgroundFetch();

      print('🔧 Initial appointment fetch and notification scheduling...');
      await refreshAppointments(doctorId);

      _isUserInitialized = true;
      print('✅ Phase 2: User services completed for doctor $doctorId');

    } catch (e) {
      print('❌ Phase 2 error: $e');
      // Don't throw to keep app functional
    }
  }

  Future<void> _initializeTimezone() async {
    tz.initializeTimeZones();
    print('✅ Timezone ready');
  }

  Future<void> _initializeDateFormatting() async {
    try {
      await initializeDateFormatting('vi', null);
      print('✅ Vietnamese locale ready');
    } catch (e) {
      print('❌ Locale error: $e');
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

    // Create notification channels
    await _createNotificationChannels();
    await _checkAndRequestPermissions();

    print('✅ Notifications ready');
  }

  Future<void> _createNotificationChannels() async {
    final androidPlugin = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      // Reminder channel
      const reminderChannel = AndroidNotificationChannel(
        'appointment_reminder_channel',
        'Appointment Reminders',
        description: 'Notifications before appointments',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      // Exact time channel
      const exactTimeChannel = AndroidNotificationChannel(
        'appointment_exact_time_channel',
        'Appointment Time',
        description: 'Notifications at appointment time',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      // Background channel
      const backgroundChannel = AndroidNotificationChannel(
        'appointment_background_channel',
        'Background Updates',
        description: 'Background appointment notifications',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      await androidPlugin.createNotificationChannel(reminderChannel);
      await androidPlugin.createNotificationChannel(exactTimeChannel);
      await androidPlugin.createNotificationChannel(backgroundChannel);

      final granted = await androidPlugin.requestNotificationsPermission();
      print('🔔 Notification permission: ${granted ?? false}');
    }
  }

  Future<void> _checkAndRequestPermissions() async {
    if (!Platform.isAndroid) return;

    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final sdkVersion = androidInfo.version.sdkInt;

      print('📱 Android SDK: $sdkVersion');

      // Request permissions based on Android version
      if (sdkVersion >= 33) {
        await Permission.notification.request();
        await Permission.scheduleExactAlarm.request();
        _hasExactAlarmPermission = await Permission.scheduleExactAlarm.isGranted;
      } else if (sdkVersion >= 31) {
        await Permission.scheduleExactAlarm.request();
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

  Future<void> loadNotificationSettings() async {
    try {
      final notificationsEnabled = await _storage.read(key: 'notifications_enabled');
      final reminderMinutes = await _storage.read(key: 'reminder_minutes');
      final exactTimeNotification = await _storage.read(key: 'exact_time_notification');

      _notificationsEnabled = notificationsEnabled != 'false';
      _reminderMinutes = int.tryParse(reminderMinutes ?? '15') ?? 15;
      _exactTimeNotification = exactTimeNotification != 'false';

      print('📱 Settings loaded: notifications=$_notificationsEnabled, '
          'minutes=$_reminderMinutes, exactTime=$_exactTimeNotification');
    } catch (e) {
      print('❌ Settings load error: $e');
    }
  }

  Future<void> _scheduleOptimizedBackgroundFetch() async {
    try {
      // Cancel existing tasks
      await Workmanager().cancelAll();

      // Initialize with optimized settings
      Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: true, // Disable debug in production
      );

      // Schedule periodic task with longer interval (1 hour)
      Workmanager().registerPeriodicTask(
        'optimized-fetch-appointments',
        fetchAppointmentsTask,
        frequency: Duration(hours: 1), // Reduced frequency
        initialDelay: Duration(minutes: 5),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: true, // Only when battery is not low
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: true,
        ),
      );

      print('✅ Optimized background tasks scheduled (1 hour interval)');
    } catch (e) {
      print('❌ Background task scheduling error: $e');
    }
  }

  // Optimized appointment fetching with cache
  Future<List<Map<String, dynamic>>> fetchAppointments(int doctorId) async {
    try {
      // Check if we fetched recently (within 10 minutes)
      if (_lastFetchTime != null &&
          DateTime.now().difference(_lastFetchTime!).inMinutes < 10) {
        print('⚡ Using recent fetch, checking cache...');
        final cached = await NotificationCacheManager.getCachedAppointments();
        if (cached != null) {
          return cached;
        }
      }

      // Fetch from API with retry logic
      final appointments = await _fetchAppointmentsWithRetry(doctorId);
      _lastFetchTime = DateTime.now();

      return appointments;
    } catch (e) {
      print('❌ Fetch appointments error: $e');

      // Fallback to cache
      final cached = await NotificationCacheManager.getCachedAppointments();
      if (cached != null) {
        print('📱 Using cached appointments as fallback');
        return cached;
      }

      throw Exception('Unable to fetch appointments and no cache available');
    }
  }

  Future<List<Map<String, dynamic>>> _fetchAppointmentsWithRetry(int doctorId) async {
    const maxRetries = 3;
    const baseDelay = Duration(seconds: 2);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final url = Uri.http('10.0.2.2:8081', '/api/v1/appointments/list', {
          'doctor_id': doctorId.toString(),
        });

        final response = await http.get(url).timeout(Duration(seconds: 30));

        if (response.statusCode == 200) {
          final allAppointments = jsonDecode(response.body) as List<dynamic>;
          print('📅 Fetched ${allAppointments.length} total appointments');

          // Modified to filter all future appointments
          final filteredAppointments = _filterFutureAppointments(allAppointments);
          print('📅 Filtered to ${filteredAppointments.length} future appointments');

          // Cache successful result
          await NotificationCacheManager.cacheAppointments(filteredAppointments);

          return filteredAppointments;
        } else {
          throw Exception('API Error: ${response.statusCode}');
        }
      } catch (e) {
        print('❌ Fetch attempt $attempt failed: $e');

        if (attempt == maxRetries) {
          rethrow;
        }

        // Exponential backoff
        await Future.delayed(baseDelay * attempt);
      }
    }

    return [];
  }

  // Modified to filter all future appointments
  List<Map<String, dynamic>> _filterFutureAppointments(List<dynamic> appointments) {
    final result = <Map<String, dynamic>>[];
    final now = DateTime.now();
    const timeSlots = [8, 9, 10, 11, 13, 14, 15, 16];

    for (var appointment in appointments) {
      try {
        final Map<String, dynamic> a = Map<String, dynamic>.from(appointment);

        if (a['status'] != 'PENDING') continue;

        final medicalDay = a['medical_day'];
        if (medicalDay == null) continue;

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

          // Include all future appointments
          if (appointmentTime.isAfter(now)) {
            result.add(a);
          }
        }
      } catch (e) {
        print('❌ Error filtering appointment: $e');
      }
    }

    // Sort by appointment time
    result.sort((a, b) {
      final timeA = _getAppointmentDateTime(a);
      final timeB = _getAppointmentDateTime(b);
      return timeA.compareTo(timeB);
    });

    return result;
  }

  DateTime _getAppointmentDateTime(Map<String, dynamic> appointment) {
    final medicalDay = DateTime.parse(appointment['medical_day'].toString());
    final slot = appointment['slot'] as int;
    const timeSlots = [8, 9, 10, 11, 13, 14, 15, 16];
    final appointmentHour = timeSlots[slot - 1];

    return DateTime(
      medicalDay.year,
      medicalDay.month,
      medicalDay.day,
      appointmentHour,
    );
  }

  String _getPatientName(Map<String, dynamic> appointment) {
    final patientList = appointment['patient'] as List<dynamic>?;
    if (patientList != null && patientList.isNotEmpty) {
      return (patientList[0] as Map<String, dynamic>)['patient_name']?.toString()
          ?? 'Patient ID: ${appointment['patient_id']}';
    }
    return 'Patient ID: ${appointment['patient_id'] ?? 'Unknown'}';
  }

  String getTimeSlot(dynamic slot) {
    const timeSlots = [8, 9, 10, 11, 13, 14, 15, 16];
    if (slot is int && slot >= 1 && slot <= 8) {
      return '${timeSlots[slot - 1]}:00';
    }
    return 'Not specified';
  }

  // Optimized notification scheduling
  Future<void> scheduleOptimizedNotifications(List<Map<String, dynamic>> appointments) async {
    if (!_notificationsEnabled) {
      print('🔕 Notifications disabled');
      return;
    }

    // Cancel all old notifications
    await cancelAllNotifications();

    final now = DateTime.now();

    // Get the start and end of today
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(Duration(days: 1));

    // Filter and sort appointments for today only (for notifications)
    final todayAppointments = appointments.where((apt) {
      try {
        final appointmentTime = _getAppointmentDateTime(apt);
        return appointmentTime.isAfter(now) && appointmentTime.isBefore(tomorrow);
      } catch (e) {
        return false;
      }
    }).toList();

    // Sort by time
    todayAppointments.sort((a, b) {
      final timeA = _getAppointmentDateTime(a);
      final timeB = _getAppointmentDateTime(b);
      return timeA.compareTo(timeB);
    });

    // Limit number of notifications (Android has limits)
    final limitedAppointments = todayAppointments.take(50).toList();

    int successCount = 0;
    List<int> scheduledIds = [];

    for (final appointment in limitedAppointments) {
      try {
        final scheduledNotificationIds = await _scheduleAppointmentNotifications(appointment);
        scheduledIds.addAll(scheduledNotificationIds);
        if (scheduledNotificationIds.isNotEmpty) successCount++;
      } catch (e) {
        print('❌ Failed to schedule notification: $e');
        continue;
      }
    }

    print('📊 Successfully scheduled $successCount/${limitedAppointments.length} notifications for today');

    // Cache all future appointments but only schedule notifications for today
    await NotificationCacheManager.cacheAppointments(appointments);
    await NotificationCacheManager.cacheScheduledNotifications(scheduledIds);
  }

  Future<List<int>> _scheduleAppointmentNotifications(Map<String, dynamic> appointment) async {
    List<int> scheduledIds = [];

    try {
      final appointmentTime = _getAppointmentDateTime(appointment);
      final patientName = _getPatientName(appointment);
      final timeSlot = getTimeSlot(appointment['slot']);

      // Calculate notification times
      final reminderTime = appointmentTime.subtract(Duration(minutes: _reminderMinutes));
      final exactTime = appointmentTime.subtract(Duration(minutes: 2));

      final now = DateTime.now();

      // Schedule reminder notification
      if (reminderTime.isAfter(now)) {
        final reminderId = NotificationIdManager.generateReminderId(appointment);
        final success = await _scheduleNotification(
          id: reminderId,
          title: 'Lịch hẹn sắp tới - $_reminderMinutes phút',
          body: 'Lịch hẹn với $patientName vào lúc $timeSlot chỉ còn $_reminderMinutes phút nữa!',
          scheduledTime: reminderTime,
          channelId: 'appointment_reminder_channel',
        );
        if (success) scheduledIds.add(reminderId);
      }

      // Schedule exact time notification
      if (_exactTimeNotification && exactTime.isAfter(now)) {
        final exactId = NotificationIdManager.generateExactTimeId(appointment);
        final success = await _scheduleNotification(
          id: exactId,
          title: 'Đã đến giờ khám!',
          body: 'Đã đến giờ khám với $patientName! Lịch hẹn lúc $timeSlot đã bắt đầu.',
          scheduledTime: exactTime,
          channelId: 'appointment_exact_time_channel',
        );
        if (success) scheduledIds.add(exactId);
      }

      return scheduledIds;
    } catch (e) {
      print('❌ Error scheduling appointment notification: $e');
      return [];
    }
  }

  Future<bool> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required String channelId,
  }) async {
    try {
      final vietnamTimeZone = tz.getLocation('Asia/Ho_Chi_Minh');
      final tzScheduledTime = tz.TZDateTime.from(scheduledTime, vietnamTimeZone);

      // Double check timing
      if (!tzScheduledTime.isAfter(tz.TZDateTime.now(vietnamTimeZone))) {
        print('⚠️ Notification time has passed: $tzScheduledTime');
        return false;
      }

      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelId == 'appointment_reminder_channel' ? 'Appointment Reminders' : 'Appointment Time',
        channelDescription: channelId == 'appointment_reminder_channel'
            ? 'Notifications before appointments'
            : 'Notifications at appointment time',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        playSound: true,
        enableVibration: true,
        styleInformation: BigTextStyleInformation(body),
      );

      final platformChannelSpecifics = NotificationDetails(android: androidDetails);

      final scheduleMode = _hasExactAlarmPermission
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

      print('✅ Scheduled notification ID $id for $tzScheduledTime');
      return true;

    } catch (e) {
      print('❌ Notification scheduling error for ID $id: $e');
      return false;
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      await NotificationCacheManager.cacheScheduledNotifications([]);
      print('🗑️ All notifications cancelled');
    } catch (e) {
      print('❌ Cancel notifications error: $e');
    }
  }

  // Main refresh method
  Future<void> refreshAppointments(int doctorId) async {
    try {
      print('🔄 Refreshing appointments for doctor $doctorId');

      final appointments = await fetchAppointments(doctorId);
      await scheduleOptimizedNotifications(appointments);

      print('✅ Appointment refresh completed');
    } catch (e) {
      print('❌ Refresh appointments error: $e');
      throw e;
    }
  }

  // Method to get pending notifications (for the viewer)
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
    } catch (e) {
      print('❌ Error getting pending notifications: $e');
      return [];
    }
  }

  // Cleanup method
  Future<void> cleanup() async {
    try {
      await cancelAllNotifications();
      await NotificationCacheManager.clearCache();
      await Workmanager().cancelAll();

      _isUserInitialized = false;
      _lastFetchTime = null;

      print('🧹 Service cleanup completed');
    } catch (e) {
      print('❌ Cleanup error: $e');
    }
  }

  // Add this method to the OptimizedAppointmentService class

// Method to fetch past appointments
  Future<List<Map<String, dynamic>>> fetchPastAppointments(int doctorId) async {
    try {
      final url = Uri.http('10.0.2.2:8081', '/api/v1/appointments/list', {
        'doctor_id': doctorId.toString(),
      });

      final response = await http.get(url).timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        final allAppointments = jsonDecode(response.body) as List<dynamic>;
        print('📅 Fetched ${allAppointments.length} total appointments for past filter');

        // Filter past appointments
        final pastAppointments = _filterPastAppointments(allAppointments);
        print('📅 Filtered to ${pastAppointments.length} past appointments');

        return pastAppointments;
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Fetch past appointments error: $e');
      throw Exception('Unable to fetch past appointments: $e');
    }
  }

// Method to filter past appointments
  List<Map<String, dynamic>> _filterPastAppointments(List<dynamic> appointments) {
    final result = <Map<String, dynamic>>[];
    final now = DateTime.now();
    const timeSlots = [8, 9, 10, 11, 13, 14, 15, 16];

    for (var appointment in appointments) {
      try {
        final Map<String, dynamic> a = Map<String, dynamic>.from(appointment);

        // Include all statuses for past appointments (COMPLETED, CANCELLED, etc.)
        final medicalDay = a['medical_day'];
        if (medicalDay == null) continue;

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

          // Include appointments that have passed
          if (appointmentTime.isBefore(now)) {
            result.add(a);
          }
        }
      } catch (e) {
        print('❌ Error filtering past appointment: $e');
      }
    }

    // Sort by appointment time (most recent first)
    result.sort((a, b) {
      final timeA = _getAppointmentDateTime(a);
      final timeB = _getAppointmentDateTime(b);
      return timeB.compareTo(timeA); // Reverse order for past appointments
    });

    return result;
  }
}