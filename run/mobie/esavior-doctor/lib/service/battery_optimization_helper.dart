import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;

class BatteryOptimizationHelper {
  static Future<bool> isBatteryOptimizationDisabled() async {
    if (!Platform.isAndroid) return true;
    
    try {
      // Không thể check trực tiếp, return false để hiển thị hướng dẫn
      return false;
    } catch (e) {
      print('❌ Battery optimization check error: $e');
      return false;
    }
  }
  
  static void showBatteryOptimizationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.battery_alert, color: Colors.orange),
            SizedBox(width: 8),
            Text('Tối ưu hóa thông báo'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Để nhận thông báo đúng giờ, vui lòng thực hiện:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 16),
              _buildStep('1', 'Vào Cài đặt > Pin'),
              _buildStep('2', 'Tìm "Tối ưu hóa pin" hoặc "Battery optimization"'),
              _buildStep('3', 'Tìm ứng dụng "Doctor App"'),
              _buildStep('4', 'Chọn "Không tối ưu hóa" hoặc "Don\'t optimize"'),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue[700], size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Điều này giúp ứng dụng hoạt động tốt hơn ở chế độ nền và gửi thông báo đúng giờ.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Để sau'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text('Mở cài đặt'),
          ),
        ],
      ),
    );
  }
  
  static Widget _buildStep(String number, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
  
  static void showPermissionEducationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Quyền thông báo'),
        content: Text(
          'Ứng dụng cần quyền thông báo để:\n\n'
          '• Nhắc nhở lịch khám sắp tới\n'
          '• Thông báo khi đến giờ khám\n'
          '• Cập nhật thay đổi lịch hẹn\n\n'
          'Vui lòng cấp quyền để sử dụng đầy đủ tính năng.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }
}
