import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class GoogleSignInButton extends StatelessWidget {
  final Function(String, String) onLoginSuccess;

  const GoogleSignInButton({required this.onLoginSuccess, Key? key}) : super(key: key);

  Future<void> _handleSignIn(BuildContext context) async {
    final GoogleSignIn _googleSignIn = GoogleSignIn(
      scopes: ['email'],
    );

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser != null) {
        String randomPassword = _generateRandomPassword();
        final response = await http.post(
          Uri.parse('http://10.0.2.2:8081/api/v1/patients/google-login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'patient_name': googleUser.displayName ?? 'No name',
            'patient_email': googleUser.email,
            'patient_password': randomPassword,
          }),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          String? patientId = data['patient_id']?.toString();
          String? patientName = data['patient_name'];

          if (patientId != null && patientName != null) {
            int parsedPatientId = int.tryParse(patientId) ?? 0; // Chuyển đổi sang int
            if (parsedPatientId > 0) {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setInt('patient_id', parsedPatientId);
              await prefs.setBool('isLoggedIn', true);

              onLoginSuccess(patientName, patientId);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Logged in successfully via Google\nAccount: ${googleUser.email}',
                  ),
                ),
              );
              // Không cần điều hướng thủ công
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Invalid patient_id from server')),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Invalid response from server')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login failed, try again.')),
          );
        }
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $error')),
      );
      print('Google sign-in error: $error');
    }
  }

  String _generateRandomPassword() {
    // Hàm này sẽ tạo một mật khẩu ngẫu nhiên
    return 'Password123@!'; // Thay bằng logic tạo mật khẩu ngẫu nhiên thực tế nếu cần
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _handleSignIn(context),
      icon: Image.asset(
        'assets/images/google_logo.png',
        height: 24.0,
        errorBuilder: (context, error, stackTrace) {
          // Fallback nếu hình ảnh không tải được
          return Icon(Icons.error, color: Colors.red);
        },
      ),
      label: Row(
        mainAxisSize: MainAxisSize.min, // Giới hạn kích thước theo nội dung
        children: [
          SizedBox(width: 8), // Khoảng cách giữa icon và text
          Expanded(
            child: Text(
              'Sign in with Google',
              textAlign: TextAlign.center, // Căn giữa text
              overflow: TextOverflow.ellipsis, // Xử lý tràn text
            ),
          ),
        ],
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        minimumSize: Size(double.infinity, 50), // Đảm bảo kích thước phù hợp
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Điều chỉnh padding
      ),
    );
  }
}