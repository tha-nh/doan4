import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:animate_do/animate_do.dart';

import 'appointment_details_screen.dart';
import 'appointments_screen.dart';
import 'doctor_profile_screen.dart';
import 'login_screen.dart';
import 'medical_records_screen.dart';

// Shared color palette
const Color primaryColor = Color(0xFF1976D2); // Vibrant blue
const Color accentColor = Color(0xFFFFB300); // Amber accent
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
  int _selectedIndex = 0;
  final List<String> _titles = [
    'Trang Chủ',
    'Lịch Hẹn',
    'Hồ Sơ Y Tế',
    'Hồ Sơ Bác Sĩ',
  ];

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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _logout() async {
    await _storage.delete(key: 'doctor_id');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
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

  Widget _buildBody() {
    if (doctorId == null) {
      return Center(child: _buildShimmerLoading());
    }

    switch (_selectedIndex) {
      case 0:
        return HomeScreenContent(doctorId: doctorId!);
      case 1:
        return AppointmentsScreen(doctorId: doctorId!);
      case 2:
        return MedicalRecordsScreen(doctorId: doctorId!);
      case 3:
        return DoctorProfileScreen(doctorId: doctorId!);
      default:
        return HomeScreenContent(doctorId: doctorId!);
    }
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 16),
          Container(width: 120, height: 16, color: Colors.white),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor, // White background for the body
      body: Container(
        color: primaryColor, // Single color for top area and AppBar
        child: SafeArea(
          child: Column(
            children: [
              // Custom AppBar without animation
              _buildAppBar(),
              Expanded(
                child: Container(
                  color: backgroundColor, // White background for the content area
                  child: _buildBody(),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: primaryColor, // Consistent with the top area
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _titles[_selectedIndex],
            style: GoogleFonts.lora(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.white, size: 24),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Chưa có thông báo mới',
                        style: GoogleFonts.lora(color: Colors.white, fontSize: 14),
                      ),
                      backgroundColor: primaryColor,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
                tooltip: 'Thông báo',
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white, size: 24),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      title: Text(
                        'Đăng Xuất',
                        style: GoogleFonts.lora(fontWeight: FontWeight.w600, fontSize: 18),
                      ),
                      content: Text(
                        'Bạn có chắc muốn đăng xuất?',
                        style: GoogleFonts.lora(fontSize: 14, color: Colors.black87),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Hủy',
                            style: GoogleFonts.lora(color: Colors.black54),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _logout();
                          },
                          child: Text(
                            'Đăng xuất',
                            style: GoogleFonts.lora(color: errorColor),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                tooltip: 'Đăng xuất',
              ),
            ],
          ),
        ],
      ),
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
            icon: Icon(Icons.home, size: 24),
            label: 'Trang Chủ',
            activeIcon: Icon(Icons.home, color: primaryColor, size: 24),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event, size: 24),
            label: 'Lịch Hẹn',
            activeIcon: Icon(Icons.event, color: primaryColor, size: 24),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services, size: 24),
            label: 'Hồ Sơ Y Tế',
            activeIcon: Icon(Icons.medical_services, color: primaryColor, size: 24),
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

class HomeScreenContent extends StatefulWidget {
  final int doctorId;

  const HomeScreenContent({super.key, required this.doctorId});

  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent> with SingleTickerProviderStateMixin {
  List<dynamic> appointments = [];
  List<dynamic> medicalRecords = [];
  bool isLoading = true;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
    _fetchData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final appointmentsResponse = await http.get(
        Uri.parse('http://10.0.2.2:8081/api/v1/doctors/${widget.doctorId}/appointments'),
      );
      final medicalRecordsResponse = await http.get(
        Uri.parse('http://10.0.2.2:8081/api/v1/doctors/${widget.doctorId}/medicalrecords'),
      );

      if (appointmentsResponse.statusCode == 200 && medicalRecordsResponse.statusCode == 200) {
        setState(() {
          appointments = jsonDecode(appointmentsResponse.body);
          medicalRecords = jsonDecode(medicalRecordsResponse.body);
          isLoading = false;
        });
        _animationController.forward(from: 0);
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Lỗi khi tải dữ liệu: $e',
            style: GoogleFonts.lora(color: Colors.white, fontSize: 14),
          ),
          backgroundColor: errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          action: SnackBarAction(
            label: 'Thử lại',
            textColor: Colors.white,
            onPressed: _fetchData,
          ),
        ),
      );
    }
  }

  List<dynamic> _getTodayAppointments() {
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return appointments.where((appointment) {
      final isPending = appointment['status'] == 'PENDING';
      final isToday = appointment['medical_day'] == todayString;
      return isPending && isToday;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final todayAppointments = _getTodayAppointments();

    return RefreshIndicator(
      onRefresh: _fetchData,
      color: primaryColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: isLoading
            ? _buildShimmerLoading()
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeInLeft(
              child: Text(
                'Hành Động Nhanh',
                style: GoogleFonts.lora(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87, // Suitable for white background
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildQuickActionButton(
                  context,
                  icon: Icons.event_available,
                  label: 'Thêm Lịch Hẹn',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Chức năng thêm lịch hẹn đang phát triển',
                          style: GoogleFonts.lora(color: Colors.white, fontSize: 14),
                        ),
                        backgroundColor: primaryColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  },
                ),
                _buildQuickActionButton(
                  context,
                  icon: Icons.description,
                  label: 'Tạo Hồ Sơ Y Tế',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Chức năng tạo hồ sơ y tế đang phát triển',
                          style: GoogleFonts.lora(color: Colors.white, fontSize: 14),
                        ),
                        backgroundColor: primaryColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            FadeInLeft(
              child: Text(
                'Lịch Hẹn Hôm Nay',
                style: GoogleFonts.lora(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87, // Suitable for white background
                ),
              ),
            ),
            const SizedBox(height: 16),
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
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
              ),
              child: Column(
                children: todayAppointments.isEmpty
                    ? [
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      'Không có lịch hẹn đang chờ xử lý hôm nay.',
                      style: GoogleFonts.lora(
                        fontSize: 14,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ]
                    : List.generate(todayAppointments.length, (index) {
                  final appointment = todayAppointments[index];
                  return FadeInUp(
                    delay: Duration(milliseconds: index * 100),
                    child: _buildAppointmentCard(appointment, index, todayAppointments.length),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(dynamic appointment, int index, int totalLength) {
    final patientName = appointment['patient'] != null && appointment['patient'].isNotEmpty
        ? appointment['patient'][0]['patient_name'] ?? 'Bệnh nhân ID: ${appointment['patient_id']}'
        : 'Bệnh nhân ID: ${appointment['patient_id'] ?? 'Không xác định'}';

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AppointmentDetailsScreen(appointment: appointment),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    backgroundColor: primaryColor.withOpacity(0.1),
                    radius: 24,
                    child: Icon(
                      Icons.person,
                      color: primaryColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patientName,
                          style: GoogleFonts.lora(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${appointment['medical_day']} - Khung giờ: ${appointment['slot'] ?? 'Chưa có'}',
                          style: GoogleFonts.lora(
                            fontSize: 14,
                            color: Colors.black54,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.videocam,
                      color: primaryColor,
                      size: 24,
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Bắt đầu cuộc gọi video',
                            style: GoogleFonts.lora(color: Colors.white, fontSize: 14),
                          ),
                          backgroundColor: primaryColor,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        if (index < totalLength - 1)
          Divider(height: 1, color: Colors.grey.shade100),
      ],
    );
  }

  Widget _buildQuickActionButton(
      BuildContext context, {
        required IconData icon,
        required String label,
        required VoidCallback onTap,
      }) {
    return Expanded(
      child: ZoomIn(
        duration: const Duration(milliseconds: 300),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(4, 4),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.7),
                  blurRadius: 8,
                  offset: const Offset(-4, -4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 32, color: primaryColor),
                      const SizedBox(height: 8),
                      Text(
                        label,
                        style: GoogleFonts.lora(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 150,
            height: 20,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 100,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  height: 100,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            width: 200,
            height: 20,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          Container(
            height: 150,
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}