import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class NotificationCacheManager {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  
  // Cache keys
  static const String _appointmentsCacheKey = 'cached_appointments';
  static const String _cacheTimestampKey = 'cache_timestamp';
  static const String _scheduledNotificationsKey = 'scheduled_notifications';
  
  // Cache expiry time (30 minutes)
  static const Duration _cacheExpiry = Duration(minutes: 30);
  
  // Cache appointments
  static Future<void> cacheAppointments(List<Map<String, dynamic>> appointments) async {
    try {
      await _storage.write(
        key: _appointmentsCacheKey,
        value: jsonEncode(appointments),
      );
      await _storage.write(
        key: _cacheTimestampKey,
        value: DateTime.now().toIso8601String(),
      );
      print('💾 Cached ${appointments.length} appointments');
    } catch (e) {
      print('❌ Cache write error: $e');
    }
  }
  
  // Get cached appointments
  static Future<List<Map<String, dynamic>>?> getCachedAppointments() async {
    try {
      final timestampStr = await _storage.read(key: _cacheTimestampKey);
      if (timestampStr == null) return null;
      
      final timestamp = DateTime.parse(timestampStr);
      final now = DateTime.now();
      
      // Check if cache is expired
      if (now.difference(timestamp) > _cacheExpiry) {
        print('⏰ Cache expired, clearing...');
        await clearCache();
        return null;
      }
      
      final cachedData = await _storage.read(key: _appointmentsCacheKey);
      if (cachedData == null) return null;
      
      final List<dynamic> appointments = jsonDecode(cachedData);
      print('💾 Retrieved ${appointments.length} cached appointments');
      return appointments.cast<Map<String, dynamic>>();
      
    } catch (e) {
      print('❌ Cache read error: $e');
      return null;
    }
  }
  
  // Clear cache
  static Future<void> clearCache() async {
    try {
      await _storage.delete(key: _appointmentsCacheKey);
      await _storage.delete(key: _cacheTimestampKey);
      await _storage.delete(key: _scheduledNotificationsKey);
      print('🗑️ Cache cleared');
    } catch (e) {
      print('❌ Cache clear error: $e');
    }
  }
  
  // Cache scheduled notification IDs
  static Future<void> cacheScheduledNotifications(List<int> notificationIds) async {
    try {
      await _storage.write(
        key: _scheduledNotificationsKey,
        value: jsonEncode(notificationIds),
      );
    } catch (e) {
      print('❌ Notification cache error: $e');
    }
  }
  
  // Get cached notification IDs
  static Future<List<int>> getCachedNotificationIds() async {
    try {
      final cachedData = await _storage.read(key: _scheduledNotificationsKey);
      if (cachedData == null) return [];
      
      final List<dynamic> ids = jsonDecode(cachedData);
      return ids.cast<int>();
    } catch (e) {
      print('❌ Notification cache read error: $e');
      return [];
    }
  }
}
