import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AppointmentsScreen extends StatefulWidget {
  final int doctorId;
  const AppointmentsScreen({super.key, required this.doctorId});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  List appointments = [];

  @override
  void initState() {
    super.initState();
    fetchAppointments();
  }

  Future<void> fetchAppointments() async {
    final url = Uri.parse('http://10.0.2.2:8081/api/v1/doctors/${widget.doctorId}/appointments');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      setState(() {
        appointments = jsonDecode(response.body);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Appointments')),
      body: ListView.builder(
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          final a = appointments[index];
          final patientName = a['patient']?[0]?['patient_name'] ?? 'Unknown';
          final staffName = a['staff']?[0]?['staff_name'] ?? 'Unknown';
          final payment = a['payment_name'] ?? 'N/A';

          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              title: Text('Patient: $patientName'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Date: ${a['appointment_date']}'),
                  Text('Slot: ${a['slot']} | Status: ${a['status']}'),
                  Text('Payment: $payment | Price: ${a['price']}'),
                  Text('Staff: $staffName'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
