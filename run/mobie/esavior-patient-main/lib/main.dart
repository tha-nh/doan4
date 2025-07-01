import 'package:esavior_project/screens/services_feedback.dart';
import 'package:esavior_project/screens/appointment_list.dart';
import 'package:esavior_project/screens/booked_list.dart';
import 'package:esavior_project/screens/change_password.dart';
import 'package:esavior_project/screens/diagnosis.dart';
import 'package:esavior_project/screens/emergency_booking.dart';
import 'package:esavior_project/screens/medical_records.dart';
import 'package:esavior_project/screens/non-urgent_booking.dart';
import 'package:flutter/material.dart';
import 'package:esavior_project/screens/about.dart';
import 'package:esavior_project/screens/appointment.dart';
import 'package:esavior_project/screens/booking.dart';
import 'package:esavior_project/screens/home.dart';
import 'package:esavior_project/screens/library.dart';
import 'package:esavior_project/screens/login.dart';
import 'package:esavior_project/screens/profile.dart';
import 'package:esavior_project/screens/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

const primaryColor = Colors.blue;
const whiteColor = Color.fromARGB(255, 255, 255, 255);
const blackColor = Color.fromARGB(255, 0, 0, 0);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isLoggedIn = true; // Đặt mặc định là true để bỏ qua login
  bool isLoading = true;
  int? patientId = 1; // Đặt patientId mặc định
  int _selectedIndex = 0;
  bool _showExtraButtons = false;

  Future<void> handleLogin(BuildContext context, int patientId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Lưu thông tin đăng nhập vào SharedPreferences
    await prefs.setBool('isLoggedIn', true);
    await prefs.setInt('patient_id', patientId);

    if (mounted) {
      setState(() {
        isLoggedIn = true;
        this.patientId = patientId;
      });
    }
  }

  void checkLoginStatus() async {
    // Bỏ qua việc kiểm tra SharedPreferences, luôn đặt là đã đăng nhập

    // Thêm delay để hiển thị loading screen
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      isLoggedIn = true; // Luôn đặt là true
      patientId = 1; // Đặt patientId mặc định
      isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

  void handleLogout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('patient_id');

    setState(() {
      isLoggedIn = false;
      patientId = null;
      _selectedIndex = 0;
      _showExtraButtons = false;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      if (index == 3) {
        _showExtraButtons = !_showExtraButtons;
      } else {
        _selectedIndex = index;
        _showExtraButtons = false;
      }
    });
  }



  // Widget cho Loading Screen với thiết kế đẹp
  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: whiteColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              whiteColor,
              Color(0xFFF8FBFF),
              Color(0xFFF0F8FF),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header với animation
              Expanded(
                flex: 2,
                child: Container(
                  width: double.infinity,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo container với hiệu ứng đẹp
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              primaryColor,
                              primaryColor.withOpacity(0.8),
                              Color(0xFF006BB3),
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.3),
                              spreadRadius: 0,
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: primaryColor.withOpacity(0.1),
                              spreadRadius: 0,
                              blurRadius: 40,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: whiteColor.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.local_hospital,
                            size: 70,
                            color: whiteColor,
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Tên app với hiệu ứng
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [
                            primaryColor,
                            Color(0xFF006BB3),
                          ],
                        ).createShader(bounds),
                        child: const Text(
                          'eSavior',
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                            color: whiteColor,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Slogan với style đẹp
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Text(
                          'Chăm sóc sức khỏe của bạn',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w400,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Loading section với animation đẹp
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Loading indicator với container đẹp
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        // color: whiteColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.1),
                            spreadRadius: 0,
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            strokeWidth: 3.5,
                            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                            backgroundColor: primaryColor.withOpacity(0.1),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Loading text
                    const Text(
                      'Đang tải...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Subtitle
                    const Text(
                      'Chuẩn bị mọi thứ cho bạn',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              // Footer
              Container(
                padding: const EdgeInsets.only(bottom: 30),
                child: Column(
                  children: [
                    // Dots indicator
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.center,
                    //   children: List.generate(3, (index) {
                    //     return Container(
                    //       margin: const EdgeInsets.symmetric(horizontal: 4),
                    //       width: 8,
                    //       height: 8,
                    //       decoration: BoxDecoration(
                    //         color: index == 0 ? primaryColor : primaryColor.withOpacity(0.3),
                    //         shape: BoxShape.circle,
                    //       ),
                    //     );
                    //   }),
                    // ),
                    //
                    // const SizedBox(height: 20),

                    // Version text
                    const Text(
                      'Version 1.0.0',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFCBD5E1),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',
      routes: {
        '/login': (context) => Login(
          onLogin: (int patientId) => handleLogin(context, patientId),
        ),
        '/user': (context) => User(
          isLoggedIn: isLoggedIn,
          onLogout: () => handleLogout(context),
          patientId: patientId,
        ),
        '/about': (context) => About(
          isLoggedIn: isLoggedIn,
          onLogout: () => handleLogout(context),
          patientId: patientId,
        ),
        '/feedback': (context) => ServicesFeedback(
          isLoggedIn: isLoggedIn,
          onLogout: () => handleLogout(context),
          patientId: patientId,
        ),
        '/library': (context) => Library(
          isLoggedIn: isLoggedIn,
          onLogout: () => handleLogout(context),
          patientId: patientId,
        ),
        '/appointment_list': (context) => AppointmentList(
          isLoggedIn: isLoggedIn,
          onLogout: () => handleLogout(context),
          patientId: patientId,
        ),
        '/medical_records': (context) => MedicalRecords(
          isLoggedIn: isLoggedIn,
          onLogout: () => handleLogout(context),
          patientId: patientId,
        ),
        '/booked_list': (context) => BookedList(
          isLoggedIn: isLoggedIn,
          onLogout: () => handleLogout(context),
          patientId: patientId,
        ),
        '/change_password': (context) => ChangePassword(
          isLoggedIn: isLoggedIn,
          onLogout: () => handleLogout(context),
          patientId: patientId,
        ),
        '/emergency_booking': (context) => EmergencyBooking(),
        '/nonEmergency_booking': (context) => NonEmergencyBooking(),
      },
      title: 'eSavior',
      theme: ThemeData(
        primarySwatch: Colors.red,
        fontFamily: 'Nunito',
      ),
      home: isLoading
          ? _buildLoadingScreen()
          : _buildMainApp(), // Bỏ điều kiện kiểm tra isLoggedIn
    );
  }

  Widget _buildMainApp() {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: whiteColor,

      body: IndexedStack(
        index: _selectedIndex,
        children: [
          Builder(
            builder: (context) => Home(
              isLoggedIn: isLoggedIn,
              onLogout: () => handleLogout(context),
              patientId: patientId,
              onNavigateToDiagnosis: () {
                setState(() {
                  _selectedIndex = 1;
                });
              },
            ),
          ),
          Builder(
            builder: (context) => Diagnosis(
              isLoggedIn: isLoggedIn,
              onLogout: () => handleLogout(context),
              patientId: patientId,
            ),
          ),
          Builder(
            builder: (context) => Appointment(
              isLoggedIn: isLoggedIn,
              onLogout: () => handleLogout(context),
              patientId: patientId,
              onNavigateToHomePage: () {
                setState(() {
                  _selectedIndex = 0;
                });
              },
            ),
          ),
          Builder(
            builder: (context) => const Booking(),
          ),
          Builder(
            builder: (context) => Profile(
              isLoggedIn: isLoggedIn,
              onLogout: () => handleLogout(context),
              patientId: patientId,
              onNavigateToDiagnosis: () {
                setState(() {
                  _selectedIndex = 1;
                });
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: whiteColor,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services),
            label: 'Diagnosis',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Medical',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.car_crash),
            label: 'Booking',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: primaryColor,
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        unselectedItemColor: Colors.black54,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildFloatingActionButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_showExtraButtons)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Builder(
              builder: (BuildContext newContext) {
                return ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(newContext, '/emergency_booking');
                    setState(() {
                      _showExtraButtons = false;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: whiteColor,
                    padding: const EdgeInsets.symmetric(
                        vertical: 16.0, horizontal: 32.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                  ),
                  child: const Text(
                    'Emergency Booking',
                    style: TextStyle(
                        fontSize: 16.0,
                        color: whiteColor,
                        fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          ),
        if (_showExtraButtons)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Builder(
              builder: (BuildContext newContext) {
                return ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(newContext, '/nonEmergency_booking');
                    setState(() {
                      _showExtraButtons = false;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: whiteColor,
                    foregroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(
                        vertical: 16.0, horizontal: 32.0),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                        side: BorderSide(color: primaryColor, width: 1.0)),
                  ),
                  child: const Text(
                    'Non-Urgent Booking',
                    style: TextStyle(
                        fontSize: 16.0,
                        color: primaryColor,
                        fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          ),
        FloatingActionButton(
          onPressed: () {
            setState(() {
              _selectedIndex = 2;
              _showExtraButtons = false;
            });
          },
          backgroundColor: primaryColor,
          child: const Icon(Icons.local_hospital, color: whiteColor, size: 30),
        ),
        if (_showExtraButtons) const SizedBox(height: 30)
      ],
    );
  }
}