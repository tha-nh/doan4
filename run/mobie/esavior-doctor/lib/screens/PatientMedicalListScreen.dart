import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'medical_record_detail_screen.dart';

// 🎨 Color and style (reuse from MedicalRecordsScreen)
const Color primaryColor = Color(0xFF0288D1);
const Color backgroundColor = Color(0xFFF5F7FA);
const Color cardColor = Colors.white;
const Color textColor = Color(0xFF1A1A1A);
const Color errorColor = Color(0xFFE57373);
const Color successColor = Color(0xFF4CAF50);
const Color warningColor = Color(0xFFFF9800);

class PatientMedicalListScreen extends StatefulWidget {
  final int patientId;
  final String patientName;

  const PatientMedicalListScreen({
    Key? key,
    required this.patientId,
    required this.patientName,
  }) : super(key: key);

  @override
  _PatientMedicalListScreenState createState() => _PatientMedicalListScreenState();
}

class _PatientMedicalListScreenState extends State<PatientMedicalListScreen> {
  List records = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    fetchRecordsByPatientId();
  }

  Future<void> fetchRecordsByPatientId() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final url = Uri.parse('http://10.0.2.2:8081/api/v1/medicalrecords/patient/${widget.patientId}');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          records = jsonDecode(response.body);
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load records';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection error';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Color _getSeverityColor(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'light':
        return successColor;
      case 'medium':
        return warningColor;
      case 'heavy':
        return Colors.deepOrange;
      case 'very heavy':
        return errorColor;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(
          'Records of ${widget.patientName}',
          style: GoogleFonts.lora(),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: GoogleFonts.lora(fontSize: 18, color: Colors.white),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : _errorMessage != null
          ? Center(
        child: Text(
          _errorMessage!,
          style: GoogleFonts.lora(color: errorColor),
        ),
      )
          : records.isEmpty
          ? Center(
        child: Text(
          'No medical records found.',
          style: GoogleFonts.lora(fontSize: 16, color: Colors.grey),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: records.length,
        itemBuilder: (context, index) {
          final record = records[index];
          final severity = record['severity']?.toString() ?? '';
          final severityColor = _getSeverityColor(severity);
          final doctorName = record['doctors']?[0]?['doctor_name'] ?? 'Unknown';
          final date = record['follow_up_date'] != null
              ? DateFormat('dd/MM/yyyy').format(DateTime.parse(record['follow_up_date']))
              : '';

          return InkWell(
              borderRadius: BorderRadius.circular(12),
          onTap: () {
          Navigator.push(
          context,
          MaterialPageRoute(
          builder: (_) => MedicalRecordDetailScreen(record: record),
          ),
          );
          },
          child: Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          date,
                          style: GoogleFonts.lora(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: severityColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          severity,
                          style: GoogleFonts.lora(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: severityColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Symptoms: ${record['symptoms'] ?? ''}',
                    style: GoogleFonts.lora(fontSize: 13, color: textColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Diagnosis: ${record['diagnosis'] ?? ''}',
                    style: GoogleFonts.lora(fontSize: 13, color: textColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Doctor: $doctorName',
                    style: GoogleFonts.lora(fontSize: 12, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ),
          );
        },
      ),
    );
  }
}
