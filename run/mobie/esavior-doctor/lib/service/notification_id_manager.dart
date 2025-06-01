class NotificationIdManager {
  // Phân chia ID ranges để tránh conflict
  static const int _reminderBaseId = 1000;      // 1000-9999
  static const int _exactTimeBaseId = 10000;    // 10000-19999
  static const int _backgroundBaseId = 20000;   // 20000-29999
  static const int _pushBaseId = 30000;         // 30000-39999
  
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
  
  // Tạo hash từ appointment data để đảm bảo consistency
  static int _generateAppointmentHash(Map<String, dynamic> appointment) {
    final medicalDay = appointment['medical_day']?.toString() ?? '';
    final slot = appointment['slot']?.toString() ?? '0';
    final patientId = appointment['patient_id']?.toString() ?? '0';
    
    final combined = '$medicalDay-$slot-$patientId';
    return combined.hashCode.abs();
  }
  
  // Kiểm tra ID có thuộc range nào
  static String getIdType(int id) {
    if (id >= _reminderBaseId && id < _exactTimeBaseId) return 'reminder';
    if (id >= _exactTimeBaseId && id < _backgroundBaseId) return 'exact_time';
    if (id >= _backgroundBaseId && id < _pushBaseId) return 'background';
    if (id >= _pushBaseId) return 'push';
    return 'unknown';
  }
}
