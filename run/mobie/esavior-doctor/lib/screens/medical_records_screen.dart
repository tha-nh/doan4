import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
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

  // Color palette matching MedicalRecordDetailScreen
  static const Color primaryColor = Color(0xFF0288D1);
  static const Color accentColor = Color(0xFFFFB300);
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color cardColor = Colors.white;
  static const Color errorColor = Color(0xFFE57373);

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
      backgroundColor: Colors.white, // Nền trắng

      body: SafeArea(
        child: _isLoading
            ? Center(
          child: CircularProgressIndicator(
            color: accentColor,
            strokeWidth: 3,
          ),
        )
            : _errorMessage != null
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage!,
                style: GoogleFonts.lora(
                  color: errorColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadDoctorIdAndFetchRecords,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  'Thử lại',
                  style: GoogleFonts.lora(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        )
            : records.isEmpty
            ? Center(
          child: Text(
            'Không có hồ sơ bệnh án nào',
            style: GoogleFonts.lora(
              fontSize: 18,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        )
            : RefreshIndicator(
          onRefresh: fetchRecords,
          color: accentColor,
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final r = records[index];
              return _buildRecordCard(r);
            },
          ),
        ),
      ),
    );
  }


  Widget _buildRecordCard(dynamic record) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MedicalRecordDetailScreen(record: record),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: primaryColor.withOpacity(0.1),
                  radius: 24,
                  child: const Icon(
                    Icons.medical_information,
                    color: primaryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bệnh nhân: ${record['patient_id'] ?? 'Không xác định'}',
                        style: GoogleFonts.lora(
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Triệu chứng: ${record['symptoms'] ?? 'Chưa có'}',
                        style: GoogleFonts.lora(
                          fontSize: 15,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                      ),
                      Text(
                        'Chẩn đoán: ${record['diagnosis'] ?? 'Chưa có'}',
                        style: GoogleFonts.lora(
                          fontSize: 15,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                      ),
                      Text(
                        'Mức độ: ${record['severity'] ?? 'Chưa có'}',
                        style: GoogleFonts.lora(
                          fontSize: 15,
                          color: Colors.black87,
                          height: 1.5,
                          fontWeight: FontWeight.w600, // Emphasize severity
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: primaryColor.withOpacity(0.5),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}