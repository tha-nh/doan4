import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Models
class Doctor {
  final int? doctorId;
  final String? doctorName;
  final int? doctorPhone;
  final String? doctorAddress;
  final String? doctorEmail;
  final int? departmentId;
  final String? doctorUsername;
  final String? doctorPassword;
  final String? summary;
  final String? doctorImage;
  final double? doctorPrice;
  final String? doctorDescription;
  final String? workingStatus;

  Doctor({
    this.doctorId,
    this.doctorName,
    this.doctorPhone,
    this.doctorAddress,
    this.doctorEmail,
    this.departmentId,
    this.doctorUsername,
    this.doctorPassword,
    this.summary,
    this.doctorImage,
    this.doctorPrice,
    this.doctorDescription,
    this.workingStatus,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      doctorId: json['doctor_id'] as int?,
      doctorName: json['doctor_name'] as String?,
      doctorPhone: json['doctor_phone'] as int?,
      doctorAddress: json['doctor_address'] as String?,
      doctorEmail: json['doctor_email'] as String?,
      departmentId: json['department_id'] as int?,
      doctorUsername: json['doctor_username'] as String?,
      doctorPassword: json['doctor_password'] as String?,
      summary: json['summary'] as String?,
      doctorImage: json['doctor_image'] as String?,
      doctorPrice: (json['doctor_price'] as num?)?.toDouble(),
      doctorDescription: json['doctor_description'] as String?,
      workingStatus: json['working_status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'doctor_id': doctorId,
      'doctor_name': doctorName,
      'doctor_phone': doctorPhone,
      'doctor_address': doctorAddress,
      'doctor_email': doctorEmail,
      'department_id': departmentId,
      'doctor_username': doctorUsername,
      'doctor_password': doctorPassword,
      'summary': summary,
      'doctor_image': doctorImage,
      'doctor_price': doctorPrice,
      'doctor_description': doctorDescription,
      'working_status': workingStatus,
    };
  }
}

class Appointment {
  final int? appointmentId;
  final int? doctorId;
  final int? staffId;

  Appointment({this.appointmentId, this.doctorId, this.staffId});

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      appointmentId: json['appointment_id'] as int?,
      doctorId: json['doctor_id'] as int?,
      staffId: json['staff_id'] as int?,
    );
  }
}

class MedicalRecord {
  final int? medicalRecordId;
  final int? doctorId;

  MedicalRecord({this.medicalRecordId, this.doctorId});

  factory MedicalRecord.fromJson(Map<String, dynamic> json) {
    return MedicalRecord(
      medicalRecordId: json['medical_record_id'] as int?,
      doctorId: json['doctor_id'] as int?,
    );
  }
}

// API Service
class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8081/api/v1/doctors';

  Future<Map<String, dynamic>?> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );
      print('Login Status Code: ${response.statusCode}');
      print('Login Response Body: ${response.body}');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Login Error: $e');
      return null;
    }
  }

  Future<List<Doctor>> getDoctors() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/list'));
      print('Get Doctors Status Code: ${response.statusCode}');
      print('Get Doctors Response Body: ${response.body}');
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Doctor.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Get Doctors Error: $e');
      return [];
    }
  }

  Future<Doctor?> getDoctorById(int id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/$id'));
      print('Get Doctor by ID Status Code: ${response.statusCode}');
      print('Get Doctor by ID Response Body: ${response.body}');
      if (response.statusCode == 200) {
        return Doctor.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      print('Get Doctor by ID Error: $e');
      return null;
    }
  }

  Future<List<Doctor>> searchDoctors(String keyword) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/search-new?keyword=$keyword'));
      print('Search Doctors Status Code: ${response.statusCode}');
      print('Search Doctors Response Body: ${response.body}');
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Doctor.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Search Doctors Error: $e');
      return [];
    }
  }

  Future<void> insertDoctor(Doctor doctor) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/insert'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(doctor.toJson()),
      );
      print('Insert Doctor Status Code: ${response.statusCode}');
      print('Insert Doctor Response Body: ${response.body}');
    } catch (e) {
      print('Insert Doctor Error: $e');
    }
  }

  Future<void> updateDoctor(Doctor doctor) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/update'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(doctor.toJson()),
      );
      print('Update Doctor Status Code: ${response.statusCode}');
      print('Update Doctor Response Body: ${response.body}');
    } catch (e) {
      print('Update Doctor Error: $e');
    }
  }

  Future<void> deleteDoctor(Doctor doctor) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/delete'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(doctor.toJson()),
      );
      print('Delete Doctor Status Code: ${response.statusCode}');
      print('Delete Doctor Response Body: ${response.body}');
    } catch (e) {
      print('Delete Doctor Error: $e');
    }
  }

  Future<List<Appointment>> getAppointmentsByDoctorId(int doctorId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/$doctorId/appointments'));
      print('Get Appointments Status Code: ${response.statusCode}');
      print('Get Appointments Response Body: ${response.body}');
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Appointment.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Get Appointments Error: $e');
      return [];
    }
  }

  Future<List<MedicalRecord>> getMedicalRecordsByDoctorId(int doctorId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/$doctorId/medicalrecords'));
      print('Get Medical Records Status Code: ${response.statusCode}');
      print('Get Medical Records Response Body: ${response.body}');
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => MedicalRecord.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Get Medical Records Error: $e');
      return [];
    }
  }
}

// Main App
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Doctors App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LoginScreen(),
      routes: {
        '/home': (context) => HomeScreen(),
        '/add': (context) => DoctorFormScreen(),
        '/search': (context) => SearchScreen(),
      },
    );
  }
}

// Login Screen
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final ApiService _apiService = ApiService();

  void _login() async {
    final result = await _apiService.login(
      _usernameController.text,
      _passwordController.text,
    );
    if (result != null) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed. Please check your credentials.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}

// Home Screen
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Doctors List'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () => Navigator.pushNamed(context, '/search'),
          ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => Navigator.pushNamed(context, '/add'),
          ),
        ],
      ),
      body: FutureBuilder<List<Doctor>>(
        future: _apiService.getDoctors(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Text('Error loading doctors'));
          }
          final doctors = snapshot.data!;
          return ListView.builder(
            itemCount: doctors.length,
            itemBuilder: (context, index) {
              final doctor = doctors[index];
              return ListTile(
                title: Text(doctor.doctorName ?? 'No Name'),
                subtitle: Text(doctor.doctorDescription ?? 'No Description'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DoctorDetailScreen(doctor: doctor),
                    ),
                  );
                },
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () async {
                    await _apiService.deleteDoctor(doctor);
                    setState(() {});
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Doctor Form Screen
class DoctorFormScreen extends StatefulWidget {
  final Doctor? doctor;

  DoctorFormScreen({this.doctor});

  @override
  _DoctorFormScreenState createState() => _DoctorFormScreenState();
}

class _DoctorFormScreenState extends State<DoctorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  final _departmentIdController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _summaryController = TextEditingController();
  final _imageController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _workingStatusController = TextEditingController();
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    if (widget.doctor != null) {
      _nameController.text = widget.doctor!.doctorName ?? '';
      _phoneController.text = widget.doctor!.doctorPhone?.toString() ?? '';
      _addressController.text = widget.doctor!.doctorAddress ?? '';
      _emailController.text = widget.doctor!.doctorEmail ?? '';
      _departmentIdController.text = widget.doctor!.departmentId?.toString() ?? '';
      _usernameController.text = widget.doctor!.doctorUsername ?? '';
      _passwordController.text = widget.doctor!.doctorPassword ?? '';
      _summaryController.text = widget.doctor!.summary ?? '';
      _imageController.text = widget.doctor!.doctorImage ?? '';
      _priceController.text = widget.doctor!.doctorPrice?.toString() ?? '';
      _descriptionController.text = widget.doctor!.doctorDescription ?? '';
      _workingStatusController.text = widget.doctor!.workingStatus ?? '';
    }
  }

  void _saveDoctor() async {
    if (_formKey.currentState!.validate()) {
      final doctor = Doctor(
        doctorId: widget.doctor?.doctorId,
        doctorName: _nameController.text,
        doctorPhone: int.tryParse(_phoneController.text),
        doctorAddress: _addressController.text,
        doctorEmail: _emailController.text,
        departmentId: int.tryParse(_departmentIdController.text),
        doctorUsername: _usernameController.text,
        doctorPassword: _passwordController.text,
        summary: _summaryController.text,
        doctorImage: _imageController.text,
        doctorPrice: double.tryParse(_priceController.text),
        doctorDescription: _descriptionController.text,
        workingStatus: _workingStatusController.text,
      );
      if (widget.doctor == null) {
        await _apiService.insertDoctor(doctor);
      } else {
        await _apiService.updateDoctor(doctor);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.doctor == null ? 'Add Doctor' : 'Edit Doctor')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Name'),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(labelText: 'Phone'),
                  keyboardType: TextInputType.phone,
                ),
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(labelText: 'Address'),
                ),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                TextFormField(
                  controller: _departmentIdController,
                  decoration: InputDecoration(labelText: 'Department ID'),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(labelText: 'Username'),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: _summaryController,
                  decoration: InputDecoration(labelText: 'Summary'),
                ),
                TextFormField(
                  controller: _imageController,
                  decoration: InputDecoration(labelText: 'Image URL'),
                ),
                TextFormField(
                  controller: _priceController,
                  decoration: InputDecoration(labelText: 'Price'),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(labelText: 'Description'),
                ),
                TextFormField(
                  controller: _workingStatusController,
                  decoration: InputDecoration(labelText: 'Working Status'),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saveDoctor,
                  child: Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Doctor Detail Screen
class DoctorDetailScreen extends StatelessWidget {
  final Doctor doctor;
  final ApiService _apiService = ApiService();

  DoctorDetailScreen({required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(doctor.doctorName ?? 'Doctor Details')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Name: ${doctor.doctorName ?? 'N/A'}'),
              Text('Phone: ${doctor.doctorPhone ?? 'N/A'}'),
              Text('Address: ${doctor.doctorAddress ?? 'N/A'}'),
              Text('Email: ${doctor.doctorEmail ?? 'N/A'}'),
              Text('Department ID: ${doctor.departmentId ?? 'N/A'}'),
              Text('Username: ${doctor.doctorUsername ?? 'N/A'}'),
              Text('Summary: ${doctor.summary ?? 'N/A'}'),
              Text('Image URL: ${doctor.doctorImage ?? 'N/A'}'),
              Text('Price: ${doctor.doctorPrice ?? 'N/A'}'),
              Text('Description: ${doctor.doctorDescription ?? 'N/A'}'),
              Text('Working Status: ${doctor.workingStatus ?? 'N/A'}'),
              SizedBox(height: 20),
              Text('Appointments:', style: TextStyle(fontWeight: FontWeight.bold)),
              FutureBuilder<List<Appointment>>(
                future: _apiService.getAppointmentsByDoctorId(doctor.doctorId ?? 0),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return Text('No appointments found');
                  }
                  final appointments = snapshot.data!;
                  return Column(
                    children: appointments
                        .map((appt) => Text('Appointment ID: ${appt.appointmentId}'))
                        .toList(),
                  );
                },
              ),
              SizedBox(height: 20),
              Text('Medical Records:', style: TextStyle(fontWeight: FontWeight.bold)),
              FutureBuilder<List<MedicalRecord>>(
                future: _apiService.getMedicalRecordsByDoctorId(doctor.doctorId ?? 0),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return Text('No medical records found');
                  }
                  final records = snapshot.data!;
                  return Column(
                    children: records
                        .map((record) => Text('Record ID: ${record.medicalRecordId}'))
                        .toList(),
                  );
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DoctorFormScreen(doctor: doctor),
                    ),
                  );
                },
                child: Text('Edit Doctor'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Search Screen
class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final ApiService _apiService = ApiService();
  List<Doctor> _searchResults = [];

  void _search() async {
    try {
      final results = await _apiService.searchDoctors(_searchController.text);
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      print('Search Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Search failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Search Doctors')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by keyword',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: _search,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final doctor = _searchResults[index];
                  return ListTile(
                    title: Text(doctor.doctorName ?? 'No Name'),
                    subtitle: Text(doctor.doctorDescription ?? 'No Description'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DoctorDetailScreen(doctor: doctor),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}