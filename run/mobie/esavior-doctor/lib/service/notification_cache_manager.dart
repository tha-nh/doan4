import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class NotificationCacheManager {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // Cache keys
  static const String _appointmentsCacheKey = 'cached_appointments';
  static const String _cacheTimestampKey = 'cache_timestamp';
  static const String _scheduledNotificationsKey = 'scheduled_notifications';
  static const String _cacheVersionKey = 'cache_version'; // NEW
  static const String _cacheHashKey = 'cache_hash'; // NEW
  static const String _conflictLogKey = 'conflict_log'; // NEW

  // Cache expiry time (30 minutes)
  static const Duration _cacheExpiry = Duration(minutes: 30);
  static const Duration _softExpiry = Duration(minutes: 10); // NEW: Soft expiry for background refresh

  // Current cache version
  static const int _currentCacheVersion = 2;

  // Cache appointments with enhanced metadata
  static Future<void> cacheAppointments(List<Map<String, dynamic>> appointments) async {
    try {
      final now = DateTime.now();
      final dataHash = _generateDataHash(appointments);

      await _storage.write(
        key: _appointmentsCacheKey,
        value: jsonEncode(appointments),
      );
      await _storage.write(
        key: _cacheTimestampKey,
        value: now.toIso8601String(),
      );
      await _storage.write(
        key: _cacheVersionKey,
        value: _currentCacheVersion.toString(),
      );
      await _storage.write(
        key: _cacheHashKey,
        value: dataHash,
      );

      print('💾 Cached ${appointments.length} appointments with hash: $dataHash');
    } catch (e) {
      print('❌ Cache write error: $e');
    }
  }

  // NEW: Cache with explicit timestamp
  static Future<void> cacheAppointmentsWithTimestamp(
      List<Map<String, dynamic>> appointments,
      DateTime timestamp,
      ) async {
    try {
      final dataHash = _generateDataHash(appointments);

      await _storage.write(
        key: _appointmentsCacheKey,
        value: jsonEncode(appointments),
      );
      await _storage.write(
        key: _cacheTimestampKey,
        value: timestamp.toIso8601String(),
      );
      await _storage.write(
        key: _cacheVersionKey,
        value: _currentCacheVersion.toString(),
      );
      await _storage.write(
        key: _cacheHashKey,
        value: dataHash,
      );

      print('💾 Cached ${appointments.length} appointments with custom timestamp');
    } catch (e) {
      print('❌ Cache write with timestamp error: $e');
    }
  }

  // Get cached appointments with enhanced validation
  static Future<List<Map<String, dynamic>>?> getCachedAppointments({
    bool ignoreSoftExpiry = false,
  }) async {
    try {
      // Check cache version
      final versionStr = await _storage.read(key: _cacheVersionKey);
      final version = int.tryParse(versionStr ?? '0') ?? 0;

      if (version < _currentCacheVersion) {
        print('⚠️ Cache version outdated ($version < $_currentCacheVersion), clearing...');
        await clearCache();
        return null;
      }

      final timestampStr = await _storage.read(key: _cacheTimestampKey);
      if (timestampStr == null) return null;

      final timestamp = DateTime.parse(timestampStr);
      final now = DateTime.now();
      final age = now.difference(timestamp);

      // Check hard expiry
      if (age > _cacheExpiry) {
        print('⏰ Cache hard expired (${age.inMinutes}min), clearing...');
        await clearCache();
        return null;
      }

      // Check soft expiry (for background refresh trigger)
      if (!ignoreSoftExpiry && age > _softExpiry) {
        print('⚠️ Cache soft expired (${age.inMinutes}min), needs background refresh');
        // Don't return null, but flag for background refresh
      }

      final cachedData = await _storage.read(key: _appointmentsCacheKey);
      if (cachedData == null) return null;

      final List<dynamic> appointments = jsonDecode(cachedData);
      final result = appointments.map((e) => Map<String, dynamic>.from(e)).toList();

      print('💾 Retrieved ${result.length} cached appointments (age: ${age.inMinutes}min)');
      return result;

    } catch (e) {
      print('❌ Cache read error: $e');
      return null;
    }
  }

  // NEW: Get cache timestamp
  static Future<DateTime?> getCacheTimestamp() async {
    try {
      final timestampStr = await _storage.read(key: _cacheTimestampKey);
      if (timestampStr != null) {
        return DateTime.parse(timestampStr);
      }
    } catch (e) {
      print('❌ Get cache timestamp error: $e');
    }
    return null;
  }

  // NEW: Check if cache needs refresh
  static Future<bool> needsRefresh() async {
    try {
      final timestamp = await getCacheTimestamp();
      if (timestamp == null) return true;

      final age = DateTime.now().difference(timestamp);
      return age > _softExpiry;
    } catch (e) {
      return true;
    }
  }

  // NEW: Check if cache is expired
  static Future<bool> isExpired() async {
    try {
      final timestamp = await getCacheTimestamp();
      if (timestamp == null) return true;

      final age = DateTime.now().difference(timestamp);
      return age > _cacheExpiry;
    } catch (e) {
      return true;
    }
  }

  // NEW: Detect data changes
  static Future<bool> hasDataChanged(List<Map<String, dynamic>> newData) async {
    try {
      final cachedHash = await _storage.read(key: _cacheHashKey);
      if (cachedHash == null) return true;

      final newHash = _generateDataHash(newData);
      final changed = cachedHash != newHash;

      if (changed) {
        print('🔄 Data changed detected: $cachedHash -> $newHash');
      }

      return changed;
    } catch (e) {
      print('❌ Change detection error: $e');
      return true;
    }
  }

  // NEW: Log conflict for debugging
  static Future<void> logConflict(String conflictType, Map<String, dynamic> details) async {
    try {
      final now = DateTime.now();
      final conflictEntry = {
        'timestamp': now.toIso8601String(),
        'type': conflictType,
        'details': details,
      };

      // Get existing log
      final existingLogStr = await _storage.read(key: _conflictLogKey);
      List<dynamic> conflictLog = [];

      if (existingLogStr != null) {
        conflictLog = jsonDecode(existingLogStr);
      }

      // Add new entry
      conflictLog.add(conflictEntry);

      // Keep only last 10 entries
      if (conflictLog.length > 10) {
        conflictLog = conflictLog.sublist(conflictLog.length - 10);
      }

      await _storage.write(key: _conflictLogKey, value: jsonEncode(conflictLog));

      print('📝 Logged conflict: $conflictType');
    } catch (e) {
      print('❌ Conflict logging error: $e');
    }
  }

  // NEW: Get conflict history
  static Future<List<Map<String, dynamic>>> getConflictHistory() async {
    try {
      final logStr = await _storage.read(key: _conflictLogKey);
      if (logStr != null) {
        final List<dynamic> log = jsonDecode(logStr);
        return log.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (e) {
      print('❌ Get conflict history error: $e');
    }
    return [];
  }

  // Clear cache
  static Future<void> clearCache() async {
    try {
      await _storage.delete(key: _appointmentsCacheKey);
      await _storage.delete(key: _cacheTimestampKey);
      await _storage.delete(key: _scheduledNotificationsKey);
      await _storage.delete(key: _cacheVersionKey);
      await _storage.delete(key: _cacheHashKey);
      // Keep conflict log for debugging

      print('🗑️ Cache cleared');
    } catch (e) {
      print('❌ Cache clear error: $e');
    }
  }

  // NEW: Clear all including logs
  static Future<void> clearAllCache() async {
    try {
      await clearCache();
      await _storage.delete(key: _conflictLogKey);
      print('🗑️ All cache and logs cleared');
    } catch (e) {
      print('❌ Clear all cache error: $e');
    }
  }

  // Cache scheduled notification IDs
  static Future<void> cacheScheduledNotifications(List<int> notificationIds) async {
    try {
      final data = {
        'ids': notificationIds,
        'timestamp': DateTime.now().toIso8601String(),
        'count': notificationIds.length,
      };

      await _storage.write(
        key: _scheduledNotificationsKey,
        value: jsonEncode(data),
      );

      print('💾 Cached ${notificationIds.length} notification IDs');
    } catch (e) {
      print('❌ Notification cache error: $e');
    }
  }

  // Get cached notification IDs
  static Future<List<int>> getCachedNotificationIds() async {
    try {
      final cachedData = await _storage.read(key: _scheduledNotificationsKey);
      if (cachedData == null) return [];

      final Map<String, dynamic> data = jsonDecode(cachedData);
      final List<dynamic> ids = data['ids'] ?? [];

      return ids.cast<int>();
    } catch (e) {
      print('❌ Notification cache read error: $e');
      return [];
    }
  }

  // NEW: Get cache health status
  static Future<Map<String, dynamic>> getCacheHealth() async {
    try {
      final timestamp = await getCacheTimestamp();
      final appointments = await getCachedAppointments(ignoreSoftExpiry: true);
      final notificationIds = await getCachedNotificationIds();
      final conflictHistory = await getConflictHistory();

      final now = DateTime.now();
      final age = timestamp != null ? now.difference(timestamp) : null;

      return {
        'has_cache': appointments != null,
        'appointment_count': appointments?.length ?? 0,
        'notification_count': notificationIds.length,
        'cache_timestamp': timestamp?.toIso8601String(),
        'cache_age_minutes': age?.inMinutes,
        'is_fresh': age != null ? age < _softExpiry : false,
        'is_expired': age != null ? age > _cacheExpiry : true,
        'needs_refresh': await needsRefresh(),
        'conflict_count': conflictHistory.length,
        'cache_version': _currentCacheVersion,
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'has_cache': false,
      };
    }
  }

  // Generate hash for data integrity check
  static String _generateDataHash(List<Map<String, dynamic>> appointments) {
    try {
      // Create a stable representation of the data
      final sortedData = appointments.map((apt) {
        return {
          'id': apt['id'],
          'medical_day': apt['medical_day'],
          'slot': apt['slot'],
          'status': apt['status'],
          'patient_id': apt['patient_id'],
        };
      }).toList();

      // Sort by ID to ensure consistent ordering
      sortedData.sort((a, b) => (a['id'] ?? 0).compareTo(b['id'] ?? 0));

      final dataString = jsonEncode(sortedData);
      return dataString.hashCode.abs().toString();
    } catch (e) {
      return DateTime.now().millisecondsSinceEpoch.toString();
    }
  }
}
