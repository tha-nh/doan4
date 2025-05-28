import 'package:flutter/material.dart';
import 'appointments_screen.dart';
import 'medical_records_screen.dart';
import 'doctor_profile_screen.dart';

class HomeScreen extends StatelessWidget {
  final int doctorId;
  const HomeScreen({required this.doctorId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Doctor Home')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => AppointmentsScreen(doctorId: doctorId))),
            child: Text('Appointments'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => MedicalRecordsScreen(doctorId: doctorId))),
            child: Text('Medical Records'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => DoctorProfileScreen(doctorId: doctorId))),
            child: Text('Doctor Profile'),
          ),
        ],
      ),
    );
  }
}
