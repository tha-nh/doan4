import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'medical_record_detail_screen.dart'; // Import the detail screen

class MedicalRecordsScreen extends StatefulWidget {
  const MedicalRecordsScreen({super.key, required this.doctorId});
  final int doctorId;

  @override
  State<MedicalRecordsScreen> createState() => _MedicalRecordsScreenState();
}

class _MedicalRecordsScreenState extends State<MedicalRecordsScreen> {
  final _storage = const FlutterSecureStorage();
  List records = [];
  int? doctorId;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDoctorIdAndFetchRecords();
  }

  Future<void> _loadDoctorIdAndFetchRecords() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    String? idString = await _storage.read(key: 'doctor_id');
    if (idString != null) {
      setState(() {
        doctorId = int.tryParse(idString);
      });
      if (doctorId != null) {
        await fetchRecords();
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> fetchRecords() async {
    final url = Uri.parse('http://10.0.2.2:8081/api/v1/doctors/$doctorId/medicalrecords');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          records = jsonDecode(response.body);
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = 'Lỗi khi tải danh sách hồ sơ bệnh án';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi kết nối. Vui lòng thử lại!';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(


      body: SafeArea(
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
                onPressed: _loadDoctorIdAndFetchRecords,
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
            : records.isEmpty
            ? const Center(
          child: Text(
            'Không có hồ sơ bệnh án nào',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        )
            : RefreshIndicator(
          onRefresh: fetchRecords,
          color: Colors.blueAccent,
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final r = records[index];
              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16.0),
                  leading: CircleAvatar(
                    backgroundColor: Colors.blueAccent.withOpacity(0.1),
                    child: const Icon(
                      Icons.medical_information,
                      color: Colors.blueAccent,
                      size: 30,
                    ),
                  ),
                  title: Text(
                    'Bệnh nhân: ${r['patient_id'] ?? 'Không xác định'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        'Triệu chứng: ${r['symptoms'] ?? 'Chưa có'}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        'Chẩn đoán: ${r['diagnosis'] ?? 'Chưa có'}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        'Mức độ: ${r['severity'] ?? 'Chưa có'}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MedicalRecordDetailScreen(record: r),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}