import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting

class AppointmentDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> appointment;

  const AppointmentDetailsScreen({super.key, required this.appointment});

  String _formatDate(String? date) {
    if (date == null) return 'Chưa có';
    try {
      final parsedDate = DateTime.parse(date);
      return DateFormat('dd/MM/yyyy').format(parsedDate);
    } catch (e) {
      return date;
    }
  }

  @override
  Widget build(BuildContext context) {
    final patientName = appointment['patient'] != null && appointment['patient'].isNotEmpty
        ? appointment['patient'][0]['patient_name'] ?? 'Bệnh nhân ID: ${appointment['patient_id']}'
        : 'Bệnh nhân ID: ${appointment['patient_id'] ?? 'Không xác định'}';
    final staffName = appointment['staff'] != null && appointment['staff'].isNotEmpty
        ? appointment['staff'][0]['staff_name'] ?? 'Không xác định'
        : 'Không xác định';
    final doctorName = appointment['doctor'] != null && appointment['doctor'].isNotEmpty
        ? appointment['doctor'][0]['doctor_name'] ?? 'Không xác định'
        : 'Không xác định';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Chi Tiết Lịch Hẹn',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thông Tin Hẹn Khám',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow('Mã lịch hẹn', appointment['appointment_id']?.toString() ?? 'Không xác định'),
                  _buildDetailRow('Bệnh nhân', patientName),
                  _buildDetailRow('Bác sĩ', doctorName),
                  _buildDetailRow('Nhân viên', staffName),
                  _buildDetailRow('Ngày đặt', _formatDate(appointment['appointment_date'])),
                  _buildDetailRow('Ngày khám', _formatDate(appointment['medical_day'])),
                  _buildDetailRow('Khung giờ', appointment['slot']?.toString() ?? 'Chưa có'),
                  _buildDetailRow('Trạng thái', appointment['status'] ?? 'Chưa xác định'),
                  _buildDetailRow('Thanh toán', appointment['payment_name'] ?? 'Chưa có'),
                  _buildDetailRow('Giá', '${appointment['price']?.toString() ?? '0'} VND'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}