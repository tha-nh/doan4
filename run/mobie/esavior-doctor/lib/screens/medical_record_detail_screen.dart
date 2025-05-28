import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MedicalRecordDetailScreen extends StatelessWidget {
  final dynamic record;

  const MedicalRecordDetailScreen({super.key, required this.record});

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
    final imageUrl = record['image'];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chi Tiết Hồ Sơ Bệnh Án',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Mã hồ sơ', record['record_id']?.toString() ?? 'Không xác định'),
                  const SizedBox(height: 12),
                  _buildDetailRow('Mã bệnh nhân', record['patient_id']?.toString() ?? 'Không xác định'),
                  const SizedBox(height: 12),
                  _buildDetailRow('Triệu chứng', record['symptoms'] ?? 'Chưa có'),
                  const SizedBox(height: 12),
                  _buildDetailRow('Chẩn đoán', record['diagnosis'] ?? 'Chưa có'),
                  const SizedBox(height: 12),
                  _buildDetailRow('Điều trị', record['treatment'] ?? 'Chưa có'),
                  const SizedBox(height: 12),
                  _buildDetailRow('Đơn thuốc', record['prescription'] ?? 'Chưa có'),
                  const SizedBox(height: 12),
                  _buildDetailRow('Tái khám', _formatDate(record['follow_up_date'])),
                  const SizedBox(height: 12),
                  _buildDetailRow('Mức độ', record['severity']?.toString() ?? 'Chưa có'),
                  const SizedBox(height: 12),
                  _buildDetailRow('Bác sĩ', record['doctor_id']?.toString() ?? 'Không xác định'),
                  if (imageUrl != null) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Hình ảnh',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Image.network(
                      imageUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Text(
                        'Không thể tải hình ảnh',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.blueAccent),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
      ],
    );
  }
}