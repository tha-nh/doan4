import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'edit_doctor.dart';
import 'login_screen.dart';

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key, required this.doctorId});
  final int doctorId;

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  final _storage = const FlutterSecureStorage();
  Map<String, dynamic>? doctor;
  int? doctorId;
  bool _isLoading = true;

  // Define color palette
  static const Color primaryColor = Color(0xFF0288D1); // Blue accent
  static const Color secondaryColor = Color(0xFFF5F5F5); // Light background
  static const Color errorColor = Color(0xFFD32F2F); // Red for errors

  @override
  void initState() {
    super.initState();
    _loadDoctorIdAndFetch();
  }

  Future<void> _loadDoctorIdAndFetch() async {
    try {
      String? idString = await _storage.read(key: 'doctor_id');
      if (idString != null) {
        doctorId = int.tryParse(idString);
        if (doctorId != null) {
          await fetchDoctor();
        }
      }
    } catch (e) {
      _showSnackBar('Lỗi khi tải thông tin. Vui lòng thử lại!');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> fetchDoctor() async {
    final url = Uri.parse('http://10.0.2.2:8081/api/v1/doctors/$doctorId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          doctor = jsonDecode(response.body);
        });
      } else {
        _showSnackBar('Lỗi khi tải thông tin bác sĩ');
      }
    } catch (e) {
      _showSnackBar('Lỗi kết nối. Vui lòng thử lại!');
    }
  }

  Future<void> _logout() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await _storage.delete(key: 'doctor_id');
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (e) {
      _showSnackBar('Lỗi khi đăng xuất. Vui lòng thử lại!');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: errorColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: secondaryColor,

      body: _isLoading || doctor == null
          ? const Center(
        child: CircularProgressIndicator(color: primaryColor),
      )
          : ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 24),
          _buildProfileCard(),
          const SizedBox(height: 24),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        AnimatedOpacity(
          opacity: doctor!['doctor_image'] != null ? 1.0 : 0.7,
          duration: const Duration(milliseconds: 500),
          child: CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey[300],
            child: doctor!['doctor_image'] != null &&
                doctor!['doctor_image'].isNotEmpty
                ? ClipOval(
              child: Image.network(
                doctor!['doctor_image'],
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const CircularProgressIndicator(
                    color: primaryColor,
                  );
                },
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.person,
                  size: 60,
                  color: primaryColor,
                ),
              ),
            )
                : const Icon(
              Icons.person,
              size: 60,
              color: primaryColor,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          doctor!['doctor_name'],
          style: GoogleFonts.poppins(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: primaryColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProfileCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileItem('Tên đăng nhập', doctor!['doctor_username']),
            _buildProfileItem('Tên', doctor!['doctor_name']),
            _buildProfileItem('Email', doctor!['doctor_email']),
            _buildProfileItem('Số điện thoại', doctor!['doctor_phone'].toString()),
            _buildProfileItem('Địa chỉ', doctor!['doctor_address']),
            _buildProfileItem('Khoa', 'Khoa ${doctor!['department_id']}'),
            _buildProfileItem('Giá khám', '${doctor!['doctor_price']} VND'),
            _buildProfileItem('Tóm tắt', doctor!['summary'] ?? 'Chưa có tóm tắt'),
            _buildProfileItem(
                'Mô tả', doctor!['doctor_description'] ?? 'Chưa có mô tả'),
            _buildProfileItem(
                'Trạng thái ', doctor!['working_status'] ?? 'Không rõ'),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        AnimatedScaleButton(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EditDoctorScreen(doctorId: doctorId!),
              ),
            );
            if (result == true) {
              setState(() {
                _isLoading = true;
              });
              await fetchDoctor();
              setState(() {
                _isLoading = false;
              });
            }
          },
          child: Text(
            'Sửa thông tin',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          color: primaryColor,
        ),
        const SizedBox(height: 16),
        AnimatedScaleButton(
          onPressed: _isLoading ? null : _logout,
          child: _isLoading
              ? const CircularProgressIndicator(
            color: errorColor,
            strokeWidth: 2,
          )
              : Text(
            'Đăng xuất',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: errorColor,
            ),
          ),
          color: Colors.white,
          borderColor: errorColor,
          isOutlined: true,
        ),
      ],
    );
  }
}

// Custom widget for animated button
class AnimatedScaleButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color color;
  final Color? borderColor;
  final bool isOutlined;

  const AnimatedScaleButton({
    super.key,
    required this.onPressed,
    required this.child,
    required this.color,
    this.borderColor,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 1.0, end: 1.0),
      duration: const Duration(milliseconds: 100),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Material(
            color: isOutlined ? Colors.transparent : color,
            borderRadius: BorderRadius.circular(12),
            elevation: isOutlined ? 0 : 2,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  border: isOutlined
                      ? Border.all(color: borderColor ?? Colors.transparent)
                      : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: child),
              ),
            ),
          ),
        );
      },
      child: child,
    );
  }
}