import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'appointment_details_screen.dart'; // Import the details screen

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key, required this.doctorId});
  final int doctorId;

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final _storage = const FlutterSecureStorage();
  List appointments = [];
  int? _doctorId;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDoctorIdAndFetch();
  }

  Future<void> _loadDoctorIdAndFetch() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final idString = await _storage.read(key: 'doctor_id');
    if (idString != null) {
      setState(() {
        _doctorId = int.tryParse(idString);
      });
      if (_doctorId != null) {
        await fetchAppointments();
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> fetchAppointments() async {
    final url = Uri.parse('http://10.0.2.2:8081/api/v1/doctors/$_doctorId/appointments');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          appointments = jsonDecode(response.body);
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = 'Lỗi khi tải danh sách lịch hẹn';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi kết nối. Vui lòng thử lại!';
      });
    }
  }

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
    // Define the start of today (00:00 on May 28, 2025)
    final todayStart = DateTime(2025, 5, 28, 0, 0, 0);

    // Filter appointments to show only those with status "PENDING" and medical_day on or after today
    final pendingAppointments = appointments.where((a) {
      final isPending = a['status'] == 'PENDING';
      if (!isPending) return false;
      final medicalDay = a['medical_day'];
      if (medicalDay == null) return false;
      try {
        final parsedMedicalDay = DateTime.parse(medicalDay);
        return parsedMedicalDay.isAfter(todayStart) || parsedMedicalDay.isAtSameMomentAs(todayStart);
      } catch (e) {
        return false;
      }
    }).toList();

    return Scaffold(
        backgroundColor: Colors.white,

      body: SafeArea(
        child: Column(
          children: [

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
                  : _errorMessage != null
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadDoctorIdAndFetch,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Thử lại',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              )
                  : pendingAppointments.isEmpty
                  ? const Center(
                child: Text(
                  'Không có lịch hẹn đang chờ xử lý từ hôm nay trở đi',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              )
                  : RefreshIndicator(
                onRefresh: fetchAppointments,
                color: Colors.blueAccent,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: pendingAppointments.length,
                  itemBuilder: (context, index) {
                    final a = pendingAppointments[index];
                    final patientName = a['patient'] != null && a['patient'].isNotEmpty
                        ? a['patient'][0]['patient_name'] ?? 'Bệnh nhân ID: ${a['patient_id']}'
                        : 'Bệnh nhân ID: ${a['patient_id'] ?? 'Không xác định'}';
                    final staffName = a['staff'] != null && a['staff'].isNotEmpty
                        ? a['staff'][0]['staff_name'] ?? 'Không xác định'
                        : 'Không xác định';
                    final status = a['status'] ?? 'Chưa xác định';

                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16.0),
                        leading: CircleAvatar(
                          backgroundColor: Colors.blueAccent.withOpacity(0.1),
                          child: const Icon(
                            Icons.event,
                            color: Colors.blueAccent,
                            size: 30,
                          ),
                        ),
                        title: Text(
                          patientName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Text('Ngày khám: ${_formatDate(a['medical_day'])}'),
                            Text('Khung giờ: ${a['slot'] ?? 'Chưa có'} | Trạng thái: $status'),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AppointmentDetailsScreen(appointment: a),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}