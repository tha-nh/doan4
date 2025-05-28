import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // For date formatting
import 'appointments_screen.dart';
import 'login_screen.dart';
import 'medical_records_screen.dart';
import 'doctor_profile_screen.dart';
import 'appointment_details_screen.dart'; // Import the details screen

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
    'Trang chủ',
    'Lịch hẹn',
    'Hồ sơ y tế',
    'Hồ sơ bác sĩ',
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải thông tin: $e')),
      );
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

  Widget _buildBody() {
    if (doctorId == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.blueAccent),
            SizedBox(height: 16),
            Text(
              'Đang tải dữ liệu...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex],
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chưa có thông báo mới')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Đăng xuất'),
                  content: const Text('Bạn có chắc muốn đăng xuất?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Hủy'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _logout();
                      },
                      child: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildBody(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Trang chủ',
            activeIcon: Icon(Icons.home, color: Colors.blueAccent),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Lịch hẹn',
            activeIcon: Icon(Icons.event, color: Colors.blueAccent),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services),
            label: 'Hồ sơ y tế',
            activeIcon: Icon(Icons.medical_services, color: Colors.blueAccent),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Hồ sơ',
            activeIcon: Icon(Icons.person, color: Colors.blueAccent),
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

class _HomeScreenContentState extends State<HomeScreenContent> {
  List<dynamic> appointments = [];
  List<dynamic> medicalRecords = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
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
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải dữ liệu: $e')),
      );
    }
  }

  // Filter appointments for today with PENDING status
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.blueAccent),
            SizedBox(height: 16),
            Text(
              'Đang tải dữ liệu...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      )
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Actions
          const Text(
            'Hành động nhanh',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildQuickActionButton(
                context,
                icon: Icons.event_available,
                label: 'Thêm lịch hẹn',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Chức năng thêm lịch hẹn đang phát triển')),
                  );
                },
              ),
              _buildQuickActionButton(
                context,
                icon: Icons.description,
                label: 'Tạo hồ sơ y tế',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Chức năng create hồ sơ y tế đang phát triển')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Upcoming Appointments (Today, PENDING only)
          const Text(
            'Lịch hẹn hôm nay',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: todayAppointments.isEmpty
                  ? [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Không có lịch hẹn đang chờ xử lý hôm nay.'),
                ),
              ]
                  : todayAppointments.map((appointment) {
                final patientName = appointment['patient'] != null && appointment['patient'].isNotEmpty
                    ? appointment['patient'][0]['patient_name'] ?? 'Bệnh nhân ID: ${appointment['patient_id']}'
                    : 'Bệnh nhân ID: ${appointment['patient_id'] ?? 'Không xác định'}';
                return Column(
                  children: [
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.blueAccent,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text(patientName),
                      subtitle: Text('${appointment['medical_day']} - Khung giờ: ${appointment['slot'] ?? 'Chưa có'}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.videocam, color: Colors.blueAccent),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Bắt đầu cuộc gọi video')),
                          );
                        },
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AppointmentDetailsScreen(appointment: appointment),
                          ),
                        );
                      },
                    ),
                    if (appointment != todayAppointments.last) const Divider(height: 1),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 30, color: Colors.blueAccent),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}