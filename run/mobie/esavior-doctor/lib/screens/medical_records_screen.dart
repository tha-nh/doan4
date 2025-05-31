import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'medical_record_detail_screen.dart';

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

  DateTime? startDate;
  DateTime? endDate;

  static const Color primaryColor = Color(0xFF0288D1);
  static const Color accentColor = Color(0xFFFFB300);
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
    final url = Uri.parse('http://10.0.2.2:8081/api/v1/medicalrecords/doctor/$doctorId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> fetchedRecords = jsonDecode(response.body);
        final DateTime now = DateTime.now();
        final DateTime effectiveStartDate = startDate ?? now.subtract(const Duration(days: 15));
        final DateTime effectiveEndDate = endDate ?? now;

        setState(() {
          records = fetchedRecords.where((r) {
            final recordDate = DateTime.tryParse(r['follow_up_date'] ?? '') ?? DateTime(1970, 1, 1);
            return (recordDate.isAtSameMomentAs(effectiveStartDate) || recordDate.isAfter(effectiveStartDate)) &&
                (recordDate.isAtSameMomentAs(effectiveEndDate) || recordDate.isBefore(effectiveEndDate));
          }).toList()
            ..sort((a, b) {
              final dateA = DateTime.tryParse(a['follow_up_date'] ?? '') ?? DateTime(1970, 1, 1);
              final dateB = DateTime.tryParse(b['follow_up_date'] ?? '') ?? DateTime(1970, 1, 1);
              return dateB.compareTo(dateA);
            });
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
      backgroundColor: Colors.white,
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
            : Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: startDate ?? DateTime.now().subtract(const Duration(days: 15)),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            startDate = picked;
                          });
                          await fetchRecords();
                        }
                      },
                      child: Text(
                        startDate == null
                            ? 'Từ ngày'
                            : 'Từ: ${startDate!.toLocal().toIso8601String().substring(0, 10)}',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: endDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            endDate = picked;
                          });
                          await fetchRecords();
                        }
                      },
                      child: Text(
                        endDate == null
                            ? 'Đến ngày'
                            : 'Đến: ${endDate!.toLocal().toIso8601String().substring(0, 10)}',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: records.isEmpty
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
          ],
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
                          fontWeight: FontWeight.w600,
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
