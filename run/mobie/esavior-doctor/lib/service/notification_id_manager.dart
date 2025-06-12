class NotificationIdManager {
  // Phân chia ID ranges để tránh conflict
  static const int _reminderBaseId = 1000;      // 1000-9999
  static const int _exactTimeBaseId = 10000;    // 10000-19999
  static const int _backgroundBaseId = 20000;   // 20000-29999
  static const int _pushBaseId = 30000;         // 30000-39999
  static const int _conflictResolveBaseId = 40000; // 40000-49999 (NEW)

  // Tạo ID duy nhất từ appointment data
  static int generateReminderId(Map<String, dynamic> appointment) {
    final hash = _generateAppointmentHash(appointment);
    return _reminderBaseId + (hash % 9000);
  }

  static int generateExactTimeId(Map<String, dynamic> appointment) {
    final hash = _generateAppointmentHash(appointment);
    return _exactTimeBaseId + (hash % 9000);
  }

  static int generateBackgroundId(int index) {
    return _backgroundBaseId + (index % 9000);
  }

  static int generatePushId() {
    return _pushBaseId + DateTime.now().millisecondsSinceEpoch % 9000;
  }

  // NEW: Generate ID for conflict resolution notifications
  static int generateConflictResolveId() {
    return _conflictResolveBaseId + DateTime.now().millisecondsSinceEpoch % 9000;
  }

  // NEW: Generate versioned ID để track changes
  static int generateVersionedId(Map<String, dynamic> appointment, String type, int version) {
    final baseHash = _generateAppointmentHash(appointment);
    final versionHash = (baseHash + version * 1000) % 9000;

    switch (type) {
      case 'reminder':
        return _reminderBaseId + versionHash;
      case 'exact_time':
        return _exactTimeBaseId + versionHash;
      default:
        return _backgroundBaseId + versionHash;
    }
  }

  // Tạo hash từ appointment data để đảm bảo consistency
  static int _generateAppointmentHash(Map<String, dynamic> appointment) {
    final medicalDay = appointment['medical_day']?.toString() ?? '';
    final slot = appointment['slot']?.toString() ?? '0';
    final patientId = appointment['patient_id']?.toString() ?? '0';
    final status = appointment['status']?.toString() ?? 'PENDING'; // NEW: Include status

    final combined = '$medicalDay-$slot-$patientId-$status';
    return combined.hashCode.abs();
  }

  // NEW: Generate stable hash không phụ thuộc vào status (for comparison)
  static int _generateStableHash(Map<String, dynamic> appointment) {
    final medicalDay = appointment['medical_day']?.toString() ?? '';
    final slot = appointment['slot']?.toString() ?? '0';
    final patientId = appointment['patient_id']?.toString() ?? '0';

    final combined = '$medicalDay-$slot-$patientId';
    return combined.hashCode.abs();
  }

  // NEW: Check if two appointments are the same (ignoring status)
  static bool isSameAppointment(Map<String, dynamic> apt1, Map<String, dynamic> apt2) {
    return _generateStableHash(apt1) == _generateStableHash(apt2);
  }

  // NEW: Generate conflict-safe ID set for an appointment
  static Map<String, int> generateAppointmentIdSet(Map<String, dynamic> appointment) {
    return {
      'reminder_id': generateReminderId(appointment),
      'exact_time_id': generateExactTimeId(appointment),
      'stable_hash': _generateStableHash(appointment),
      'full_hash': _generateAppointmentHash(appointment),
    };
  }

  // Kiểm tra ID có thuộc range nào
  static String getIdType(int id) {
    if (id >= _reminderBaseId && id < _exactTimeBaseId) return 'reminder';
    if (id >= _exactTimeBaseId && id < _backgroundBaseId) return 'exact_time';
    if (id >= _backgroundBaseId && id < _pushBaseId) return 'background';
    if (id >= _pushBaseId && id < _conflictResolveBaseId) return 'push';
    if (id >= _conflictResolveBaseId) return 'conflict_resolve';
    return 'unknown';
  }

  // NEW: Get all possible IDs for an appointment
  static List<int> getAllAppointmentIds(Map<String, dynamic> appointment) {
    return [
      generateReminderId(appointment),
      generateExactTimeId(appointment),
    ];
  }

  // NEW: Validate ID ranges
  static bool isValidId(int id) {
    return id >= _reminderBaseId && id < 50000; // Max range
  }

  // NEW: Debug info for an appointment
  static Map<String, dynamic> getDebugInfo(Map<String, dynamic> appointment) {
    final idSet = generateAppointmentIdSet(appointment);
    return {
      'appointment_id': appointment['id'],
      'medical_day': appointment['medical_day'],
      'slot': appointment['slot'],
      'patient_id': appointment['patient_id'],
      'status': appointment['status'],
      'generated_ids': idSet,
      'all_notification_ids': getAllAppointmentIds(appointment),
    };
  }
}
