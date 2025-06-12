import 'notification_id_manager.dart';
import 'notification_cache_manager.dart';

class CacheConflictResolver {
  // Detect conflicts between cached and fresh data
  static Future<ConflictResult> detectConflicts(
    List<Map<String, dynamic>> cachedData,
    List<Map<String, dynamic>> freshData,
  ) async {
    final conflicts = <ConflictDetail>[];
    
    try {
      // Check for missing appointments
      for (final cached in cachedData) {
        final fresh = freshData.firstWhere(
          (item) => NotificationIdManager.isSameAppointment(cached, item),
          orElse: () => {},
        );
        
        if (fresh.isEmpty) {
          conflicts.add(ConflictDetail(
            type: ConflictType.appointmentDeleted,
            appointmentId: cached['id'],
            description: 'Appointment ${cached['id']} was deleted',
            cachedValue: cached,
            freshValue: null,
          ));
        }
      }
      
      // Check for new appointments
      for (final fresh in freshData) {
        final cached = cachedData.firstWhere(
          (item) => NotificationIdManager.isSameAppointment(fresh, item),
          orElse: () => {},
        );
        
        if (cached.isEmpty) {
          conflicts.add(ConflictDetail(
            type: ConflictType.appointmentAdded,
            appointmentId: fresh['id'],
            description: 'New appointment ${fresh['id']} was added',
            cachedValue: null,
            freshValue: fresh,
          ));
        }
      }
      
      // Check for field changes
      for (final cached in cachedData) {
        final fresh = freshData.firstWhere(
          (item) => NotificationIdManager.isSameAppointment(cached, item),
          orElse: () => {},
        );
        
        if (fresh.isNotEmpty) {
          final fieldConflicts = _detectFieldConflicts(cached, fresh);
          conflicts.addAll(fieldConflicts);
        }
      }
      
      final result = ConflictResult(
        hasConflicts: conflicts.isNotEmpty,
        conflicts: conflicts,
        severity: _calculateSeverity(conflicts),
      );
      
      // Log conflicts
      if (result.hasConflicts) {
        await NotificationCacheManager.logConflict('data_conflict', {
          'conflict_count': conflicts.length,
          'severity': result.severity.toString(),
          'conflicts': conflicts.map((c) => c.toMap()).toList(),
        });
      }
      
      return result;
      
    } catch (e) {
      print('❌ Conflict detection error: $e');
      return ConflictResult(
        hasConflicts: true,
        conflicts: [
          ConflictDetail(
            type: ConflictType.systemError,
            appointmentId: null,
            description: 'Error during conflict detection: $e',
            cachedValue: null,
            freshValue: null,
          )
        ],
        severity: ConflictSeverity.high,
      );
    }
  }
  
  // Detect field-level conflicts
  static List<ConflictDetail> _detectFieldConflicts(
    Map<String, dynamic> cached,
    Map<String, dynamic> fresh,
  ) {
    final conflicts = <ConflictDetail>[];
    final criticalFields = ['status', 'slot', 'medical_day'];
    final importantFields = ['patient_id'];
    
    for (final field in criticalFields) {
      if (cached[field] != fresh[field]) {
        conflicts.add(ConflictDetail(
          type: ConflictType.fieldChanged,
          appointmentId: cached['id'],
          description: 'Field $field changed from ${cached[field]} to ${fresh[field]}',
          cachedValue: cached[field],
          freshValue: fresh[field],
          field: field,
          severity: ConflictSeverity.high,
        ));
      }
    }
    
    for (final field in importantFields) {
      if (cached[field] != fresh[field]) {
        conflicts.add(ConflictDetail(
          type: ConflictType.fieldChanged,
          appointmentId: cached['id'],
          description: 'Field $field changed from ${cached[field]} to ${fresh[field]}',
          cachedValue: cached[field],
          freshValue: fresh[field],
          field: field,
          severity: ConflictSeverity.medium,
        ));
      }
    }
    
    return conflicts;
  }
  
  // Calculate overall conflict severity
  static ConflictSeverity _calculateSeverity(List<ConflictDetail> conflicts) {
    if (conflicts.isEmpty) return ConflictSeverity.none;
    
    final hasHigh = conflicts.any((c) => c.severity == ConflictSeverity.high);
    final hasMedium = conflicts.any((c) => c.severity == ConflictSeverity.medium);
    
    if (hasHigh) return ConflictSeverity.high;
    if (hasMedium) return ConflictSeverity.medium;
    return ConflictSeverity.low;
  }
  
  // Resolve conflicts automatically
  static Future<ResolutionResult> resolveConflicts(
    ConflictResult conflictResult,
    List<Map<String, dynamic>> freshData,
  ) async {
    try {
      if (!conflictResult.hasConflicts) {
        return ResolutionResult(
          success: true,
          message: 'No conflicts to resolve',
          actionsPerformed: [],
        );
      }
      
      final actions = <String>[];
      
      // High severity conflicts require cache invalidation
      if (conflictResult.severity == ConflictSeverity.high) {
        await NotificationCacheManager.clearCache();
        actions.add('Cleared cache due to high severity conflicts');
        
        // Cache fresh data
        await NotificationCacheManager.cacheAppointments(freshData);
        actions.add('Cached fresh data');
      }
      
      // Medium severity conflicts can be resolved by updating cache
      else if (conflictResult.severity == ConflictSeverity.medium) {
        await NotificationCacheManager.cacheAppointments(freshData);
        actions.add('Updated cache with fresh data');
      }
      
      // Log resolution
      await NotificationCacheManager.logConflict('conflict_resolved', {
        'severity': conflictResult.severity.toString(),
        'actions': actions,
        'conflict_count': conflictResult.conflicts.length,
      });
      
      return ResolutionResult(
        success: true,
        message: 'Conflicts resolved successfully',
        actionsPerformed: actions,
      );
      
    } catch (e) {
      print('❌ Conflict resolution error: $e');
      return ResolutionResult(
        success: false,
        message: 'Failed to resolve conflicts: $e',
        actionsPerformed: [],
      );
    }
  }
}

// Data classes for conflict management
enum ConflictType {
  appointmentDeleted,
  appointmentAdded,
  fieldChanged,
  systemError,
}

enum ConflictSeverity {
  none,
  low,
  medium,
  high,
}

class ConflictDetail {
  final ConflictType type;
  final dynamic appointmentId;
  final String description;
  final dynamic cachedValue;
  final dynamic freshValue;
  final String? field;
  final ConflictSeverity severity;
  
  ConflictDetail({
    required this.type,
    required this.appointmentId,
    required this.description,
    required this.cachedValue,
    required this.freshValue,
    this.field,
    this.severity = ConflictSeverity.medium,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'type': type.toString(),
      'appointment_id': appointmentId,
      'description': description,
      'cached_value': cachedValue,
      'fresh_value': freshValue,
      'field': field,
      'severity': severity.toString(),
    };
  }
}

class ConflictResult {
  final bool hasConflicts;
  final List<ConflictDetail> conflicts;
  final ConflictSeverity severity;
  
  ConflictResult({
    required this.hasConflicts,
    required this.conflicts,
    required this.severity,
  });
}

class ResolutionResult {
  final bool success;
  final String message;
  final List<String> actionsPerformed;
  
  ResolutionResult({
    required this.success,
    required this.message,
    required this.actionsPerformed,
  });
}
