import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';

import 'appointments_screen.dart';
import 'medical_records_screen.dart';
import 'doctor_profile_screen.dart';


// Shared color palette
const Color primaryColor = Color(0xFF1976D2); // Vibrant blue
const Color backgroundColor = Colors.white;
const Color cardColor = Color(0xFFF5F7FA);
const Color errorColor = Color(0xFFE57373);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.doctorId});
  final int doctorId;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storage = const FlutterSecureStorage();
  int? doctorId;
  int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    _loadDoctorInfo();
  }

  Future<void> _loadDoctorInfo() async {
    try {
      String? idString = await _storage.read(key: 'doctor_id');
      setState(() {
        doctorId = idString != null ? int.tryParse(idString) : widget.doctorId;
      });
    } catch (e) {
      _showErrorSnackBar('Lỗi khi tải thông tin: $e');
      setState(() {
        doctorId = widget.doctorId;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.lora(color: Colors.white, fontSize: 14),
        ),
        backgroundColor: errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'Thử lại',
          textColor: Colors.white,
          onPressed: _loadDoctorInfo,
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildBody() {
    if (doctorId == null) {
      return const Center(child: CircularProgressIndicator(color: primaryColor));
    }

    switch (_selectedIndex) {
      case 0:
        return MedicalRecordsScreen(doctorId: doctorId!);
      case 1:
        return AppointmentsScreen(doctorId: doctorId!);
      case 2:
        return DoctorProfileScreen(doctorId: doctorId!);
      default:
        return AppointmentsScreen(doctorId: doctorId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: _buildBody(),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.black54,
        backgroundColor: cardColor,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.lora(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: GoogleFonts.lora(fontWeight: FontWeight.w400, fontSize: 12),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services, size: 24),
            label: 'Hồ Sơ Y Tế',
            activeIcon: Icon(Icons.medical_services, color: primaryColor, size: 24),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event, size: 24),
            label: 'Lịch Khám',
            activeIcon: Icon(Icons.event, color: primaryColor, size: 24),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, size: 24),
            label: 'Hồ Sơ',
            activeIcon: Icon(Icons.person, color: primaryColor, size: 24),
          ),
        ],
      ),
    );
  }
}