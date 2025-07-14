import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';
import '../service/appointment_service.dart';
import 'scheduled_notifications_viewer.dart';


class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _storage = const FlutterSecureStorage();

  // Cài đặt thông báo
  bool _notificationsEnabled = true;
  int _reminderMinutes = 15; // Mặc định 15 phút trước
  bool _exactTimeNotification = true; // Thông báo khi đến giờ (2 phút trước)
  bool _hasExactAlarmPermission = false;

  // Danh sách các tùy chọn thời gian nhắc nhở
  final List<int> _reminderOptions = [5, 10, 15, 30, 60]; // phút

  // Color palette
  static const Color primaryColor = Color(0xFF1976D2);
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color cardColor = Colors.white;

  final _appointmentService = OptimizedAppointmentService();
  int? _doctorId;

  // Track if there are unsaved changes
  bool _originalNotificationsEnabled = true;
  int _originalReminderMinutes = 15;
  bool _originalExactTimeNotification = true;

  bool get _hasUnsavedChanges {
    return _notificationsEnabled != _originalNotificationsEnabled ||
        _reminderMinutes != _originalReminderMinutes ||
        _exactTimeNotification != _originalExactTimeNotification;
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadDoctorId();
    _checkPermissions();
  }

  Future<void> _loadSettings() async {
    try {
      final notificationsEnabled = await _storage.read(key: 'notifications_enabled');
      final reminderMinutes = await _storage.read(key: 'reminder_minutes');
      final exactTimeNotification = await _storage.read(key: 'exact_time_notification');

      final notifications = notificationsEnabled != 'false';
      final reminder = int.tryParse(reminderMinutes ?? '15') ?? 15;
      final exactTime = exactTimeNotification != 'false';

      setState(() {
        // Set both original and current values
        _originalNotificationsEnabled = notifications;
        _originalReminderMinutes = reminder;
        _originalExactTimeNotification = exactTime;

        _notificationsEnabled = notifications;
        _reminderMinutes = reminder;
        _exactTimeNotification = exactTime;
      });
    } catch (e) {
      print('Lỗi khi tải cài đặt: $e');
    }
  }

  Future<void> _loadDoctorId() async {
    try {
      final idString = await _storage.read(key: 'doctor_id');
      if (idString != null) {
        _doctorId = int.tryParse(idString);
      }
    } catch (e) {
      print('Lỗi khi tải doctor ID: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      await _storage.write(key: 'notifications_enabled', value: _notificationsEnabled.toString());
      await _storage.write(key: 'reminder_minutes', value: _reminderMinutes.toString());
      await _storage.write(key: 'exact_time_notification', value: _exactTimeNotification.toString());

      // Update original values to match current values
      setState(() {
        _originalNotificationsEnabled = _notificationsEnabled;
        _originalReminderMinutes = _reminderMinutes;
        _originalExactTimeNotification = _exactTimeNotification;
      });

      // Reload settings in AppointmentService
      await _appointmentService.loadNotificationSettings();

      // Reschedule notifications with new settings if doctor ID is available
      if (_doctorId != null) {
        _showSnackBar('Updating announcement schedule...', Colors.blue);

        try {
          await _appointmentService.refreshAppointments(_doctorId!);
          _showSnackBar('Settings saved and notification updated successfully', Colors.green);
        } catch (e) {
          print('Error updating notification: $e');
          _showSnackBar('Settings saved but error updating notification', Colors.orange);
        }
      } else {
        _showSnackBar('Settings saved successfully', Colors.green);
      }
    } catch (e) {
      _showSnackBar('Error saving settings: $e', Colors.red);
    }
  }

  void _resetSettings() {
    setState(() {
      _notificationsEnabled = _originalNotificationsEnabled;
      _reminderMinutes = _originalReminderMinutes;
      _exactTimeNotification = _originalExactTimeNotification;
    });
  }

  Future<void> _checkPermissions() async {
    if (!Platform.isAndroid) return;

    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final sdkVersion = androidInfo.version.sdkInt;

      if (sdkVersion >= 31) {
        final exactAlarmStatus = await Permission.scheduleExactAlarm.status;
        setState(() {
          _hasExactAlarmPermission = exactAlarmStatus.isGranted;
        });
      } else {
        setState(() {
          _hasExactAlarmPermission = true;
        });
      }
    } catch (e) {
      print('Error checking permissions: $e');
    }
  }

  Future<void> _requestExactAlarmPermission() async {
    if (!Platform.isAndroid) return;

    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;

      if (androidInfo.version.sdkInt >= 31) {
        final result = await Permission.scheduleExactAlarm.request();
        setState(() {
          _hasExactAlarmPermission = result.isGranted;
        });

        if (result.isGranted) {
          _showSnackBar('Correct notification permission granted', Colors.green);
        } else {
          _showExactAlarmPermissionDialog();
        }
      }
    } catch (e) {
      _showSnackBar('Error requesting permission: $e', Colors.red);
    }
  }

  void _showExactAlarmPermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Need accurate notification rights',
            style: GoogleFonts.lora(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'To receive timely notifications, please:\n\n'
                '1. Go to Settings > Apps\n'
                '2. Find this app\n'
                '3. Select "Special permissions"\n'
                '4. Turn on "Alarms and reminders"',
            style: GoogleFonts.lora(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Understood', style: GoogleFonts.lora()),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: Text('Open settings', style: GoogleFonts.lora()),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.lora(color: Colors.white),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _viewScheduledNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ScheduledNotificationsViewer(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Setting',
          style: GoogleFonts.lora(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        // actions: [
        //   // Nút xem thông báo đã lập lịch
        //   IconButton(
        //     onPressed: _viewScheduledNotifications,
        //     icon: const Icon(Icons.schedule),
        //     tooltip: 'View scheduled notifications',
        //   ),
        // ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Reset button (only show if there are unsaved changes)
          if (_hasUnsavedChanges) ...[
            FloatingActionButton.extended(
              onPressed: _resetSettings,
              backgroundColor: Colors.grey[600],
              foregroundColor: Colors.white,
              icon: const Icon(Icons.refresh),
              label: Text(
                'Reset',
                style: GoogleFonts.lora(fontWeight: FontWeight.w600),
              ),
              heroTag: "reset",
            ),
            const SizedBox(width: 16),
          ],
          // Save button
          FloatingActionButton.extended(
            onPressed: _hasUnsavedChanges ? _saveSettings : null,
            backgroundColor: _hasUnsavedChanges ? primaryColor : Colors.grey[400],
            foregroundColor: Colors.white,
            icon: const Icon(Icons.save),
            label: Text(
              'Save settings',
              style: GoogleFonts.lora(fontWeight: FontWeight.w600),
            ),
            heroTag: "save",
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Show unsaved changes indicator
            if (_hasUnsavedChanges)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You have unsaved changes. Click "Save Settings" to apply.',
                        style: GoogleFonts.lora(
                          fontSize: 14,
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            _buildNotificationSection(),
            const SizedBox(height: 24),
            _buildPermissionSection(),
            // const SizedBox(height: 24),
            // _buildNotificationManagementSection(),
            const SizedBox(height: 24),
            _buildAboutSection(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSection() {
    return Card(
      color: cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notifications, color: primaryColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Notification Settings',
                  style: GoogleFonts.lora(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            SwitchListTile(
              title: Text(
                'Turn on appointment notification',
                style: GoogleFonts.lora(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                'Get notified about upcoming appointments',
                style: GoogleFonts.lora(fontSize: 14, color: Colors.grey[600]),
              ),
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
              },
              activeColor: primaryColor,
            ),

            if (_notificationsEnabled) ...[
              const Divider(),

              ListTile(
                title: Text(
                  'Reminder Time',
                  style: GoogleFonts.lora(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  'Get notified $_reminderMinutes minutes in advance',
                  style: GoogleFonts.lora(fontSize: 14, color: Colors.grey[600]),
                ),
                trailing: DropdownButton<int>(
                  value: _reminderMinutes,
                  items: _reminderOptions.map((minutes) {
                    return DropdownMenuItem<int>(
                      value: minutes,
                      child: Text(
                        '$minutes minutes',
                        style: GoogleFonts.lora(),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _reminderMinutes = value;
                      });
                    }
                  },
                ),
              ),

              SwitchListTile(
                title: Text(
                  'Notification When It\'s Time for Your Appointment',
                  style: GoogleFonts.lora(fontSize: 16, fontWeight: FontWeight.w500),
                ),

                subtitle: Text(
                  'Get notified "It\'s time for your appointment"" ',
                  style: GoogleFonts.lora(fontSize: 14, color: Colors.grey[600]),
                ),
                value: _exactTimeNotification,
                onChanged: (value) {
                  setState(() {
                    _exactTimeNotification = value;
                  });
                },
                activeColor: primaryColor,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionSection() {
    return Card(
      color: cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.security, color: primaryColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Application Permissions',
                  style: GoogleFonts.lora(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            ListTile(
              leading: Icon(
                _hasExactAlarmPermission ? Icons.check_circle : Icons.warning,
                color: _hasExactAlarmPermission ? Colors.green : Colors.orange,
              ),
              title: Text(
                'Correct notice',
                style: GoogleFonts.lora(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                _hasExactAlarmPermission
                    ? 'Permission granted'
                    : 'Permission not granted',
                style: GoogleFonts.lora(
                  fontSize: 14,
                  color: _hasExactAlarmPermission ? Colors.green : Colors.orange,
                ),
              ),
              trailing: _hasExactAlarmPermission
                  ? null
                  : ElevatedButton(
                onPressed: _requestExactAlarmPermission,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: Text('Grant permissions', style: GoogleFonts.lora()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildNotificationManagementSection() {
  //   return Card(
  //     color: cardColor,
  //     elevation: 2,
  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  //     child: Padding(
  //       padding: const EdgeInsets.all(16),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Row(
  //             children: [
  //               Icon(Icons.manage_history, color: primaryColor, size: 24),
  //               const SizedBox(width: 8),
  //               Text(
  //                 'Notification Management',
  //                 style: GoogleFonts.lora(
  //                   fontSize: 18,
  //                   fontWeight: FontWeight.w600,
  //                   color: primaryColor,
  //                 ),
  //               ),
  //             ],
  //           ),
  //           const SizedBox(height: 16),
  //
  //           ListTile(
  //             leading: Container(
  //               padding: const EdgeInsets.all(8),
  //               decoration: BoxDecoration(
  //                 color: primaryColor.withOpacity(0.1),
  //                 borderRadius: BorderRadius.circular(8),
  //               ),
  //               child: Icon(Icons.schedule, color: primaryColor),
  //             ),
  //             title: Text(
  //               'View scheduled notifications',
  //               style: GoogleFonts.lora(fontSize: 16, fontWeight: FontWeight.w500),
  //             ),
  //             subtitle: Text(
  //               'View list of notifications waiting to be sent',
  //               style: GoogleFonts.lora(fontSize: 14, color: Colors.grey[600]),
  //             ),
  //             trailing: const Icon(Icons.arrow_forward_ios, size: 16),
  //             onTap: _viewScheduledNotifications,
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildAboutSection() {
    return Card(
      color: cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: primaryColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Information',
                  style: GoogleFonts.lora(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Text(
              'The notification system will send:',
              style: GoogleFonts.lora(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),

            if (_notificationsEnabled) ...[
              _buildInfoItem('• Notify $_reminderMinutes minutes before the appointment time to prepare'),
              if (_exactTimeNotification)
                _buildInfoItem('• "Time for examination" notification '),
            ] else ...[
              _buildInfoItem('• Notifications have been disabled'),
            ],

            const SizedBox(height: 12),
            Text(
              'Note: For notifications to work best, make sure the app is not battery optimized.',
              style: GoogleFonts.lora(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        text,
        style: GoogleFonts.lora(fontSize: 14, color: Colors.grey[700]),
      ),
    );
  }
}
