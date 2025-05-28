import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class EditDoctorScreen extends StatefulWidget {
  final int doctorId;
  const EditDoctorScreen({super.key, required this.doctorId});

  @override
  State<EditDoctorScreen> createState() => _EditDoctorScreenState();
}

class _EditDoctorScreenState extends State<EditDoctorScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  final _summaryController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchDoctorData();
  }

  Future<void> fetchDoctorData() async {
    final url = Uri.parse('http://10.0.2.2:8081/api/v1/doctors/${widget.doctorId}');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final doctor = jsonDecode(response.body);
      setState(() {
        _nameController.text = doctor['doctor_name'] ?? '';
        _phoneController.text = doctor['doctor_phone']?.toString() ?? '';
        _addressController.text = doctor['doctor_address'] ?? '';
        _emailController.text = doctor['doctor_email'] ?? '';
        _summaryController.text = doctor['summary'] ?? '';
        _descriptionController.text = doctor['doctor_description'] ?? '';
      });
    }
  }

  Future<void> _updateDoctor() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final updatedData = {
      "doctor_id": widget.doctorId,
      "doctor_name": _nameController.text,
      "doctor_phone": int.tryParse(_phoneController.text),
      "doctor_address": _addressController.text,
      "doctor_email": _emailController.text,
      "summary": _summaryController.text,
      "doctor_description": _descriptionController.text,
    };

    final url = Uri.parse('http://10.0.2.2:8081/api/v1/doctors/update');
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(updatedData),
    );

    setState(() => _isLoading = false);

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật thành công')),
      );
      Navigator.pop(context, true);
      // Quay về trang trước
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật thất bại')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chỉnh sửa thông tin bác sĩ')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Họ tên'),
                validator: (value) => value!.isEmpty ? 'Không để trống' : null,
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Số điện thoại'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Địa chỉ'),
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextFormField(
                controller: _summaryController,
                decoration: const InputDecoration(labelText: 'Tóm tắt'),
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Mô tả chi tiết'),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateDoctor,
                child: const Text('Lưu thay đổi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
