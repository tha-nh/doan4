import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🧪 Notification Debug Test', () {
    late FlutterLocalNotificationsPlugin plugin;

    setUp(() async {
      plugin = FlutterLocalNotificationsPlugin();
      tz.initializeTimeZones();

      const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

      await plugin.initialize(initializationSettings);
      await plugin.cancelAll(); // reset notification trước mỗi test
    });

    test('Gửi notification test và kiểm tra trong pending list', () async {
      final location = tz.getLocation('Asia/Ho_Chi_Minh');
      final now = tz.TZDateTime.now(location);
      final scheduleTime = now.add(const Duration(seconds: 10));

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'test_channel',
        'Test Channel',
        channelDescription: 'Kênh test notification',
        importance: Importance.max,
        priority: Priority.high,
      );

      final NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

      await plugin.zonedSchedule(
        10001, // ID cố định để dễ kiểm tra
        '🔔 Thông báo test',
        'Đây là nội dung notification test',
        scheduleTime,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,

      );

      final pending = await plugin.pendingNotificationRequests();

      expect(pending.length, greaterThanOrEqualTo(1));

      final testNotif = pending.firstWhere(
            (n) => n.id == 10001,
        orElse: () => throw Exception('❌ Notification không được lập lịch'),
      );

      print('✅ Đã lập lịch: ${testNotif.title} - ${testNotif.body}');
      expect(testNotif.title, contains('Thông báo test'));
      expect(testNotif.body, contains('notification test'));
    });
  });
}
