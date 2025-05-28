import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MedicalRecordsScreen extends StatefulWidget {
  final int doctorId;
  const MedicalRecordsScreen({super.key, required this.doctorId});

  @override
  State<MedicalRecordsScreen> createState() => _MedicalRecordsScreenState();
}

class _MedicalRecordsScreenState extends State<MedicalRecordsScreen> {
  List records = [];

  @override
  void initState() {
    super.initState();
    fetchRecords();
  }

  Future<void> fetchRecords() async {
    final url = Uri.parse('http://10.0.2.2:8081/api/v1/doctors/${widget.doctorId}/medicalrecords');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      setState(() {
        records = jsonDecode(response.body);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medical Records')),
      body: ListView.builder(
        itemCount: records.length,
        itemBuilder: (context, index) {
          final r = records[index];
          final imageUrl = r['image'];

          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              title: Text('Patient: ${r['patient_id']}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Symptoms: ${r['symptoms']}'),
                  Text('Diagnosis: ${r['diagnosis']}'),
                  Text('Treatment: ${r['treatment']}'),
                  Text('Follow-up: ${r['follow_up_date']}'),
                  Text('Severity: ${r['severity']}'),
                  if (imageUrl != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Image.network('http://10.0.2.2:8081/uploads/$imageUrl', height: 120),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
