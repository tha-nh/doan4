import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'edit_doctor.dart';
import 'login_screen.dart';
import 'package:image_picker/image_picker.dart';



class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key, required this.doctorId});
  final int doctorId;

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> with SingleTickerProviderStateMixin {
  final _storage = const FlutterSecureStorage();
  Map<String, dynamic>? doctor;
  int? doctorId;
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  // Color palette to match AppointmentsScreen
  static const Color primaryColor = Color(0xFF0288D1);
  static const Color accentColor = Color(0xFFFFB300);
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color cardColor = Colors.white;
  static const Color errorColor = Color(0xFFE57373);
  static const Color textColor = Color(0xFF1A1A1A);

  @override
  void initState() {
    super.initState();
    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuad,
    ));
    if (mounted) {
      _animationController.forward();
    }
    _loadDoctorIdAndFetch();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadDoctorIdAndFetch() async {
    setState(() {
      _isLoading = true;
    });
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
    // Show confirmation dialog
    bool? confirmLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            'Xác nhận đăng xuất',
            style: GoogleFonts.lora(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          content: Text(
            'Bạn có chắc chắn muốn đăng xuất?',
            style: GoogleFonts.lora(
              fontSize: 14,
              color: textColor,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Cancel
              child: Text(
                'Hủy',
                style: GoogleFonts.lora(
                  fontSize: 14,
                  color: primaryColor,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // Confirm
              child: Text(
                'Đăng xuất',
                style: GoogleFonts.lora(
                  fontSize: 14,
                  color: errorColor,
                ),
              ),
            ),
          ],
        );
      },
    );

    // Proceed with logout only if confirmed
    if (confirmLogout == true) {
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
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.lora(
            fontSize: 14,
            color: Colors.white,
          ),
        ),
        backgroundColor: errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _pickAndUploadImage() async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Chọn từ thư viện'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Chụp ảnh'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile == null) return;

    final imageBytes = await pickedFile.readAsBytes();
    final base64Image = base64Encode(imageBytes);

    const imgbbApiKey = 'fa4176aa6360d22d4809f8799fbdf498'; // Thay bằng API key của bạn
    final uploadUrl = Uri.parse('https://api.imgbb.com/1/upload?key=$imgbbApiKey');

    try {
      final response = await http.post(uploadUrl, body: {
        'image': base64Image,
      });

      if (response.statusCode == 200) {
        final imageUrl = jsonDecode(response.body)['data']['url'];
        await _updateDoctorImage(imageUrl);
      } else {
        _showSnackBar('Không thể tải ảnh lên.');
      }
    } catch (e) {
      _showSnackBar('Lỗi kết nối khi upload ảnh');
    }
  }


  Future<void> _updateDoctorImage(String imageUrl) async {
    final updateUrl = Uri.parse('http://10.0.2.2:8081/api/v1/doctors/update');
    final response = await http.put(
      updateUrl,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'doctor_id': doctorId,
        'doctor_image': imageUrl,
      }),
    );

    if (response.statusCode == 200) {
      _showSnackBar('Cập nhật ảnh thành công!');
      await fetchDoctor(); // Làm mới UI
    } else {
      _showSnackBar('Cập nhật ảnh thất bại.');
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      body: SafeArea(
        child: _isLoading || doctor == null
            ? Center(
          child: CircularProgressIndicator(
            color: accentColor,
            strokeWidth: 4,
          ),
        )
            : SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(),
                const SizedBox(height: 20),
                _buildProfileCard(),
                const SizedBox(height: 20),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),

      child:Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: primaryColor.withOpacity(0.2),
                child: doctor!['doctor_image'] != null && doctor!['doctor_image'].isNotEmpty
                    ? ClipOval(
                  child: Image.network(
                    doctor!['doctor_image'],
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.person, size: 40, color: primaryColor),
                  ),
                )
                    : const Icon(Icons.person, size: 40, color: primaryColor),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickAndUploadImage, // Gọi hàm upload
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctor!['doctor_name'],
                  style: GoogleFonts.lora(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  'ID: ${doctorId ?? 'Không xác định'}',
                  style: GoogleFonts.lora(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),


    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileItem('Tên đăng nhập', doctor!['doctor_username']),
          _buildProfileItem('Tên', doctor!['doctor_name']),
          _buildProfileItem('Email', doctor!['doctor_email']),
          _buildProfileItem('Số điện thoại', ' 0${doctor!['doctor_phone'].toString()}'),
          _buildProfileItem('Địa chỉ', doctor!['doctor_address']),
          _buildProfileItem('Khoa', 'Khoa ${doctor!['department_id']}'),
          _buildProfileItem('Giá khám', '${(doctor!['doctor_price'] as num).toInt()} VND'),

          _buildProfileItem('Tóm tắt', doctor!['summary'] ?? 'Chưa có tóm tắt'),
          _buildProfileItem('Mô tả', doctor!['doctor_description'] ?? 'Chưa có mô tả'),
          _buildProfileItem('Trạng thái', doctor!['working_status'] ?? 'Không rõ'),
        ],
      ),
    );
  }

  Widget _buildProfileItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.lora(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.lora(
              fontSize: 14,
              color: textColor,
              height: 1.4,
            ),
          ),
          const Divider(height: 20, thickness: 1, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: ElevatedButton.icon(
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
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
            ),
            icon: const Icon(Icons.edit, size: 20),
            label: Text(
              'Sửa thông tin',
              style: GoogleFonts.lora(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _logout,
            style: ElevatedButton.styleFrom(
              backgroundColor: errorColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
            ),
            icon: _isLoading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
                : const Icon(Icons.logout, size: 20),
            label: Text(
              'Đăng xuất',
              style: GoogleFonts.lora(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

}