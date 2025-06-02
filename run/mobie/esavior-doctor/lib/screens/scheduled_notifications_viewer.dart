import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';

import '../service/notification_cache_manager.dart';
import '../service/notification_id_manager.dart';


class ScheduledNotificationsViewer extends StatefulWidget {
  const ScheduledNotificationsViewer({super.key});

  @override
  State<ScheduledNotificationsViewer> createState() => _ScheduledNotificationsViewerState();
}

class _ScheduledNotificationsViewerState extends State<ScheduledNotificationsViewer> {
  List<PendingNotificationRequest> _pendingNotifications = [];
  List<int> _cachedNotificationIds = [];
  bool _isLoading = true;
  String? _error;

  static const Color primaryColor = Color(0xFF1976D2);
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color cardColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _loadScheduledNotifications();
  }

  Future<void> _loadScheduledNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get pending notifications from system
      final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      final pendingNotifications = await flutterLocalNotificationsPlugin.pendingNotificationRequests();
      
      // Get cached notification IDs
      final cachedIds = await NotificationCacheManager.getCachedNotificationIds();

      setState(() {
        _pendingNotifications = pendingNotifications;
        _cachedNotificationIds = cachedIds;
        _isLoading = false;
      });

      print('📊 Found ${pendingNotifications.length} pending notifications');
      print('📊 Found ${cachedIds.length} cached notification IDs');

    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      print('❌ Error loading scheduled notifications: $e');
    }
  }

  String _getNotificationType(int id) {
    return NotificationIdManager.getIdType(id);
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'reminder':
        return Colors.blue;
      case 'exact_time':
        return Colors.green;
      case 'background':
        return Colors.orange;
      case 'push':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'reminder':
        return Icons.schedule;
      case 'exact_time':
        return Icons.alarm;
      case 'background':
        return Icons.sync;
      case 'push':
        return Icons.notifications_active;
      default:
        return Icons.notification_important;
    }
  }

  String _getTypeDisplayName(String type) {
    switch (type) {
      case 'reminder':
        return 'Nhắc nhở';
      case 'exact_time':
        return 'Đến giờ';
      case 'background':
        return 'Nền';
      case 'push':
        return 'Push';
      default:
        return 'Khác';
    }
  }

  Future<void> _cancelNotification(int id) async {
    try {
      final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      await flutterLocalNotificationsPlugin.cancel(id);
      
      // Remove from cached IDs
      _cachedNotificationIds.remove(id);
      await NotificationCacheManager.cacheScheduledNotifications(_cachedNotificationIds);
      
      // Reload the list
      await _loadScheduledNotifications();
      
      _showSnackBar('Đã hủy thông báo ID: $id', Colors.green);
    } catch (e) {
      _showSnackBar('Lỗi khi hủy thông báo: $e', Colors.red);
    }
  }

  Future<void> _cancelAllNotifications() async {
    final confirmed = await _showConfirmDialog(
      'Hủy tất cả thông báo',
      'Bạn có chắc chắn muốn hủy tất cả ${_pendingNotifications.length} thông báo đã lập lịch?',
    );

    if (confirmed == true) {
      try {
        final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
        await flutterLocalNotificationsPlugin.cancelAll();
        
        // Clear cached IDs
        await NotificationCacheManager.cacheScheduledNotifications([]);
        
        // Reload the list
        await _loadScheduledNotifications();
        
        _showSnackBar('Đã hủy tất cả thông báo', Colors.green);
      } catch (e) {
        _showSnackBar('Lỗi khi hủy thông báo: $e', Colors.red);
      }
    }
  }

  Future<bool?> _showConfirmDialog(String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: GoogleFonts.lora(fontWeight: FontWeight.bold)),
        content: Text(content, style: GoogleFonts.lora()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy', style: GoogleFonts.lora()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Xác nhận', style: GoogleFonts.lora(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.lora(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showNotificationDetails(PendingNotificationRequest notification) {
    final type = _getNotificationType(notification.id);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(_getTypeIcon(type), color: _getTypeColor(type)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Chi tiết thông báo',
                style: GoogleFonts.lora(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('ID', notification.id.toString()),
              _buildDetailRow('Loại', _getTypeDisplayName(type)),
              _buildDetailRow('Tiêu đề', notification.title ?? 'Không có'),
              _buildDetailRow('Nội dung', notification.body ?? 'Không có'),
              _buildDetailRow('Payload', notification.payload ?? 'Không có'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Đóng', style: GoogleFonts.lora()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelNotification(notification.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Hủy thông báo', style: GoogleFonts.lora(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: GoogleFonts.lora(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.lora(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Thông báo đã lập lịch',
          style: GoogleFonts.lora(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadScheduledNotifications,
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
          ),
          if (_pendingNotifications.isNotEmpty)
            IconButton(
              onPressed: _cancelAllNotifications,
              icon: const Icon(Icons.clear_all),
              tooltip: 'Hủy tất cả',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Đang tải thông báo...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Lỗi khi tải thông báo',
              style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: GoogleFonts.lora(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadScheduledNotifications,
              child: Text('Thử lại', style: GoogleFonts.lora()),
            ),
          ],
        ),
      );
    }

    if (_pendingNotifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Không có thông báo nào được lập lịch',
              style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Các thông báo sẽ hiển thị ở đây khi được lập lịch',
              style: GoogleFonts.lora(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Summary card
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.schedule, color: primaryColor, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tổng số thông báo',
                      style: GoogleFonts.lora(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '${_pendingNotifications.length}',
                      style: GoogleFonts.lora(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              _buildTypeStats(),
            ],
          ),
        ),

        // Notifications list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _pendingNotifications.length,
            itemBuilder: (context, index) {
              final notification = _pendingNotifications[index];
              final type = _getNotificationType(notification.id);
              
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getTypeColor(type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getTypeIcon(type),
                      color: _getTypeColor(type),
                      size: 24,
                    ),
                  ),
                  title: Text(
                    notification.title ?? 'Không có tiêu đề',
                    style: GoogleFonts.lora(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        notification.body ?? 'Không có nội dung',
                        style: GoogleFonts.lora(fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getTypeColor(type),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getTypeDisplayName(type),
                              style: GoogleFonts.lora(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'ID: ${notification.id}',
                            style: GoogleFonts.lora(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'details':
                          _showNotificationDetails(notification);
                          break;
                        case 'cancel':
                          _cancelNotification(notification.id);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'details',
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline),
                            const SizedBox(width: 8),
                            Text('Chi tiết', style: GoogleFonts.lora()),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'cancel',
                        child: Row(
                          children: [
                            const Icon(Icons.cancel, color: Colors.red),
                            const SizedBox(width: 8),
                            Text('Hủy', style: GoogleFonts.lora(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  onTap: () => _showNotificationDetails(notification),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTypeStats() {
    final typeCount = <String, int>{};
    for (final notification in _pendingNotifications) {
      final type = _getNotificationType(notification.id);
      typeCount[type] = (typeCount[type] ?? 0) + 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: typeCount.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _getTypeColor(entry.key),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${_getTypeDisplayName(entry.key)}: ${entry.value}',
                style: GoogleFonts.lora(fontSize: 12),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
