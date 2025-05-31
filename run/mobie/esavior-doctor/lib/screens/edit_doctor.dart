import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';

class EditDoctorScreen extends StatefulWidget {
  const EditDoctorScreen({super.key, required this.doctorId});
  final int doctorId;

  @override
  State<EditDoctorScreen> createState() => _EditDoctorScreenState();
}

class _EditDoctorScreenState extends State<EditDoctorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storage = const FlutterSecureStorage();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  final _summaryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _statusController = TextEditingController();
  final _imageController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  int? _doctorId;

  @override
  void initState() {
    super.initState();
    _loadDoctorIdAndFetch();
  }

  Future<void> _loadDoctorIdAndFetch() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final idString = await _storage.read(key: 'doctor_id');
    if (idString != null) {
      setState(() {
        _doctorId = int.tryParse(idString);
      });
      if (_doctorId != null) {
        await fetchDoctorData();
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> fetchDoctorData() async {
    final url = Uri.parse('http://10.0.2.2:8081/api/v1/doctors/$_doctorId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final doctor = jsonDecode(response.body);
        setState(() {
          _nameController.text = doctor['doctor_name'] ?? '';
          // Hiển thị số điện thoại với số 0 ở đầu
          String phoneNumber = doctor['doctor_phone']?.toString() ?? '';
          if (phoneNumber.isNotEmpty) {
            _phoneController.text = '0$phoneNumber';
          }
          _addressController.text = doctor['doctor_address'] ?? '';
          _emailController.text = doctor['doctor_email'] ?? '';
          _summaryController.text = doctor['summary'] ?? '';
          _descriptionController.text = doctor['doctor_description'] ?? '';
          var price = doctor['doctor_price'];
          _priceController.text = (price is int)
              ? price.toString()
              : (price is double && price == price.toInt())
              ? price.toInt().toString()
              : price.toString();

          _statusController.text = doctor['working_status'] ?? '';
          _imageController.text = doctor['doctor_image'] ?? '';
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = 'Lỗi khi tải thông tin bác sĩ';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi kết nối. Vui lòng thử lại!';
      });
    }
  }

  Future<void> _updateDoctor() async {
    if (!_formKey.currentState!.validate() || _doctorId == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Lấy số điện thoại và bỏ số 0 ở đầu trước khi lưu
    String phoneText = _phoneController.text.trim();
    String phoneToSave = phoneText.startsWith('0') ? phoneText.substring(1) : phoneText;

    final updatedData = {
      "doctor_id": _doctorId,
      "doctor_name": _nameController.text.trim(),
      "doctor_phone": int.tryParse(phoneToSave),
      "doctor_address": _addressController.text.trim(),
      "doctor_email": _emailController.text.trim(),
      "summary": _summaryController.text.trim(),
      "doctor_description": _descriptionController.text.trim(),
      "doctor_price": double.tryParse(_priceController.text.trim()),
      "working_status": _statusController.text.trim(),
      "doctor_image": _imageController.text.trim(),
    };

    final url = Uri.parse('http://10.0.2.2:8081/api/v1/doctors/update');
    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updatedData),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cập nhật thành công',
              style: GoogleFonts.lora(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context, true);
      } else {
        setState(() {
          _errorMessage = 'Cập nhật thất bại. Vui lòng thử lại!';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi kết nối. Vui lòng thử lại!';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _summaryController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _statusController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Chỉnh sửa thông tin bác sĩ',
          style: GoogleFonts.lora(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
            : _errorMessage != null
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage!,
                style: GoogleFonts.lora(
                  fontSize: 16,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadDoctorIdAndFetch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Thử lại',
                  style: GoogleFonts.lora(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        )
            : SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Center(
                  child: Icon(
                    Icons.medical_services,
                    size: 60,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Cập nhật hồ sơ bác sĩ',
                    style: GoogleFonts.lora(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Form fields
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Họ tên',
                            labelStyle: GoogleFonts.lora(),
                            prefixIcon: const Icon(Icons.person, color: Colors.blueAccent),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          style: GoogleFonts.lora(),
                          validator: (value) =>
                          value!.trim().isEmpty ? 'Vui lòng nhập họ tên' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            labelText: 'Số điện thoại',
                            labelStyle: GoogleFonts.lora(),
                            prefixIcon: const Icon(Icons.phone, color: Colors.blueAccent),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            hintText: '0xxxxxxxxx',
                          ),
                          style: GoogleFonts.lora(),
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                            PhoneNumberFormatter(),
                          ],
                          validator: (value) {
                            if (value!.trim().isEmpty) return 'Vui lòng nhập số điện thoại';
                            if (value.trim().length != 10) return 'Số điện thoại phải có 10 chữ số';
                            if (!value.startsWith('0')) return 'Số điện thoại phải bắt đầu bằng số 0';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _addressController,
                          decoration: InputDecoration(
                            labelText: 'Địa chỉ',
                            labelStyle: GoogleFonts.lora(),
                            prefixIcon: const Icon(Icons.location_on, color: Colors.blueAccent),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          style: GoogleFonts.lora(),
                          validator: (value) =>
                          value!.trim().isEmpty ? 'Vui lòng nhập địa chỉ' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: GoogleFonts.lora(),
                            prefixIcon: const Icon(Icons.email, color: Colors.blueAccent),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          style: GoogleFonts.lora(),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value!.trim().isEmpty) return 'Vui lòng nhập email';
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                .hasMatch(value.trim())) {
                              return 'Email không hợp lệ';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _priceController,
                          decoration: InputDecoration(
                            labelText: 'Giá khám (VND)',
                            labelStyle: GoogleFonts.lora(),
                            prefixIcon: const Icon(Icons.monetization_on, color: Colors.blueAccent),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          style: GoogleFonts.lora(),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly, // chỉ cho phép số nguyên
                          ],
                          validator: (value) {
                            if (value!.trim().isEmpty) return 'Vui lòng nhập giá khám';
                            if (double.tryParse(value.trim()) == null) return 'Giá không hợp lệ';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _statusController,
                          decoration: InputDecoration(
                            labelText: 'Trạng thái làm việc',
                            labelStyle: GoogleFonts.lora(),
                            prefixIcon: const Icon(Icons.work, color: Colors.blueAccent),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          style: GoogleFonts.lora(),
                        ),

                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _summaryController,
                          decoration: InputDecoration(
                            labelText: 'Tóm tắt',
                            labelStyle: GoogleFonts.lora(),
                            prefixIcon: const Icon(Icons.description, color: Colors.blueAccent),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          style: GoogleFonts.lora(),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: InputDecoration(
                            labelText: 'Mô tả chi tiết',
                            labelStyle: GoogleFonts.lora(),
                            prefixIcon: const Icon(Icons.info, color: Colors.blueAccent),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          style: GoogleFonts.lora(),
                          maxLines: 4,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updateDoctor,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    )
                        : Text(
                      'Lưu thay đổi',
                      style: GoogleFonts.lora(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Custom formatter để tự động thêm số 0 ở đầu
class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    String newText = newValue.text;

    // Nếu người dùng xóa hết thì để trống
    if (newText.isEmpty) {
      return newValue;
    }

    // Nếu không bắt đầu bằng 0 thì thêm 0 vào đầu
    if (!newText.startsWith('0')) {
      newText = '0$newText';
    }

    // Giới hạn tối đa 10 ký tự
    if (newText.length > 10) {
      newText = newText.substring(0, 10);
    }

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}