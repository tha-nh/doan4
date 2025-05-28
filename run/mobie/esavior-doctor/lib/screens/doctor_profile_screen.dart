import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'edit_doctor.dart';

class DoctorProfileScreen extends StatefulWidget {
  final int doctorId;
  const DoctorProfileScreen({super.key, required this.doctorId});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  Map<String, dynamic>? doctor;

  @override
  void initState() {
    super.initState();
    fetchDoctor();
  }

  Future<void> fetchDoctor() async {
    final url = Uri.parse('http://10.0.2.2:8081/api/v1/doctors/${widget.doctorId}');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      setState(() {
        doctor = jsonDecode(response.body);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (doctor == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Doctor Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${doctor!['doctor_name']}', style: const TextStyle(fontSize: 18)),
            Text('Username: ${doctor!['doctor_username']}'),
            Text('Department ID: ${doctor!['department_id']}'),
            Text('Summary: ${doctor!['summary']}'),
            Text('Description: ${doctor!['doctor_description']}'),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () async {
                // Push màn hình chỉnh sửa và chờ kết quả trả về
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditDoctorScreen(doctorId: widget.doctorId),
                  ),
                );

                // Nếu kết quả là true (chỉnh sửa thành công), tải lại dữ liệu bác sĩ
                if (result == true) {
                  fetchDoctor();
                }
              },
              child: const Text('Sửa thông tin'),
            ),


          ],
        ),

      ),

    );

  }
}
