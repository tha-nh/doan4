import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

const primaryColor = Color(0xFF2196F3);
const secondaryColor = Color(0xFF1976D2);
const accentColor = Color(0xFF03DAC6);
const whiteColor = Color(0xFFFFFFFF);
const blackColor = Color(0xFF000000);
const greyColor = Color(0xFF757575);
const lightGreyColor = Color(0xFFF5F5F5);

class Diagnosis extends StatefulWidget {
  final bool isLoggedIn;
  final Function onLogout;
  final int? patientId;

  Diagnosis({required this.isLoggedIn, required this.onLogout, this.patientId});

  @override
  _DiagnosisState createState() => _DiagnosisState();
}

class _DiagnosisState extends State<Diagnosis> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<XFile>? selectedFiles = [];
  bool loading = false;
  bool isLoading = false;
  String fullText = '';
  String comparisonMessage = '';
  double severity = 0.0;
  List medicalHistory = [];
  String symptoms = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));

    if (!widget.isLoggedIn) {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ... (keeping all the existing API methods)
  Future<void> loadMedicalHistory() async {
    setState(() {
      loading = true;
    });
    try {
      final response = await http.get(
        Uri.parse(
            'http://10.0.2.2:8081/api/v1/medicalrecords/search?patient_id=${widget.patientId}'),
      );
      if (response.statusCode == 200) {
        final List history = json.decode(response.body);
        setState(() {
          medicalHistory = history;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load history: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('Error loading history: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error loading medical history')),
      );
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  Future<Map<String, dynamic>?> findPreviousDiagnosis(String conclusion) async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://10.0.2.2:8081/api/v1/medicalrecords/search?patient_id=${widget.patientId}'),
      );
      if (response.statusCode == 200) {
        final List records = json.decode(response.body);
        return records.lastWhere((record) => record['diagnosis'] == conclusion,
            orElse: () => null);
      }
    } catch (e) {
      print('Error finding previous diagnosis: $e');
    }
    return null;
  }

  Future<void> pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile>? pickedFiles = await picker.pickMultiImage();
    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      print('Selected files: ${pickedFiles.map((f) => f.path).toList()}');
      setState(() {
        selectedFiles = pickedFiles;
      });
    } else {
      print('No files selected from gallery');
    }
  }

  Future<void> pickImageFromCamera() async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      print('Picked image: ${photo.path}');
      setState(() {
        selectedFiles = [photo];
      });
    } else {
      print('No photo taken from camera');
    }
  }

  Future<void> handleSubmit() async {
    if (selectedFiles == null || selectedFiles!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one image')),
      );
      return;
    }
    if (symptoms.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter symptoms')),
      );
      return;
    }

    final uri = Uri.parse('http://10.0.2.2:8000/predict');
    final request = http.MultipartRequest('POST', uri);

    for (var file in selectedFiles!) {
      request.files.add(await http.MultipartFile.fromPath('files', file.path));
      print('Added file: ${file.path}');
    }
    request.fields['symptoms'] = symptoms;

    setState(() {
      isLoading = true;
      fullText = '';
    });

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        try {
          final result = json.decode(responseData) as Map<String, dynamic>;
          final String conclusion = result['conclusion']?.toString() ?? 'No conclusion';
          final adviceData = result['advice_and_prescription'] as Map<String, dynamic>? ?? {};
          final String advice = adviceData['advice']?.toString() ?? 'No advice';
          final String prescription = adviceData['prescription']?.toString() ?? 'No prescription';
          final double severity = (result['severity'] is num)
              ? result['severity'].toDouble()
              : double.tryParse(result['severity']?.toString() ?? '0.0') ?? 0.0;

          final previousDiagnosis = await findPreviousDiagnosis(conclusion);
          if (previousDiagnosis != null) {
            if (severity > double.parse(previousDiagnosis['severity'].toString())) {
              comparisonMessage = 'More severe than last visit.';
            } else if (severity < double.parse(previousDiagnosis['severity'].toString())) {
              comparisonMessage = 'Better than last visit.';
            } else {
              comparisonMessage = 'Same severity as last visit.';
            }
          } else {
            comparisonMessage = 'First examination for this disease.';
          }

          setState(() {
            fullText = 'Conclusion: $conclusion\nAdvice: $advice\nPrescription: $prescription';
          });

          await saveMedicalRecordToDatabase(conclusion, advice, prescription, severity.toStringAsFixed(2));
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid response from server')),
          );
        }
      } else {
        final errorData = await response.stream.bytesToString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server error: ${response.statusCode} - $errorData')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
      showDiagnosisDialog(context);
    }
  }

  Future<void> saveMedicalRecordToDatabase(String conclusion, String advice, String prescription, String severity) async {
    try {
      final uri = Uri.parse('http://10.0.2.2:8081/api/v1/medicalrecords/insert');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'patient_id': widget.patientId,
          'diagnosis': conclusion,
          'treatment': advice,
          'prescription': prescription,
          'severity': severity,
          'follow_up_date': DateTime.now().toIso8601String(),
        }),
      );
      if (response.statusCode == 200) {
        print('Medical record saved successfully');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save error: ${response.statusCode} - ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save error: $e')),
      );
    }
  }

  void showInstructionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
          title: const Text('How to Take a Photo?', style: TextStyle(color: blackColor, fontSize: 22, fontWeight: FontWeight.bold)),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('1. Take photo 4 inches from the problem area.', style: TextStyle(color: blackColor, fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('2. Center the symptom in the photo.', style: TextStyle(color: blackColor, fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('3. Ensure the photo isn\'t blurry.', style: TextStyle(color: blackColor, fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('4. Use good lighting.', style: TextStyle(color: blackColor, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('I Understand!', style: TextStyle(color: primaryColor, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void showDiagnosisDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
          title: const Text('Diagnosis Result', style: TextStyle(color: blackColor, fontSize: 22, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (fullText.isNotEmpty)
                  Text(fullText, style: const TextStyle(fontSize: 16, color: primaryColor, fontWeight: FontWeight.bold))
                else
                  const Text('No diagnosis result available. Check input or server.', style: TextStyle(fontSize: 16, color: blackColor, fontWeight: FontWeight.bold)),
                if (comparisonMessage.isNotEmpty)
                  Text(comparisonMessage, style: const TextStyle(fontSize: 16, color: blackColor, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('I Got It!', style: TextStyle(color: primaryColor, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16), // Reduced padding
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Important: Use min size
        children: [
          Container(
            padding: const EdgeInsets.all(12), // Reduced padding
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: primaryColor, size: 28), // Reduced icon size
          ),
          const SizedBox(height: 12), // Reduced spacing
          Text(
            title,
            style: const TextStyle(
              fontSize: 16, // Reduced font size
              fontWeight: FontWeight.bold,
              color: blackColor,
            ),
            textAlign: TextAlign.center,
            maxLines: 2, // Limit lines
            overflow: TextOverflow.ellipsis, // Handle overflow
          ),
          const SizedBox(height: 6), // Reduced spacing
          Flexible( // Use Flexible instead of fixed spacing
            child: Text(
              description,
              style: const TextStyle(
                fontSize: 12, // Reduced font size
                color: greyColor,
                height: 1.3, // Reduced line height
              ),
              textAlign: TextAlign.center,
              maxLines: 3, // Limit lines
              overflow: TextOverflow.ellipsis, // Handle overflow
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotLoggedInUI() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Hero Section
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      primaryColor.withOpacity(0.1),
                      whiteColor,
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(60),
                      ),
                      child: const Icon(
                        Icons.medical_services_outlined,
                        size: 60,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'AI-Powered Medical\nDiagnosis',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: blackColor,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Get instant medical insights with our advanced AI technology. Upload photos and receive professional diagnosis recommendations.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: greyColor,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),

              // Call to Action Section
              Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, secondaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.login_outlined,
                      color: whiteColor,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Ready to Get Started?',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: whiteColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Sign in to access all features and start your medical diagnosis journey',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: whiteColor,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pushNamed(context, '/login'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: whiteColor,
                          foregroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Sign In Now',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Features Section
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text(
                      'Why Choose Our Platform?',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: blackColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.1, // Increased aspect ratio for more height
                      children: [
                        _buildFeatureCard(
                          icon: Icons.camera_alt_outlined,
                          title: 'Photo Analysis',
                          description: 'Upload photos for instant AI-powered analysis',
                        ),
                        _buildFeatureCard(
                          icon: Icons.psychology_outlined,
                          title: 'AI Diagnosis',
                          description: 'Advanced algorithms provide accurate insights',
                        ),
                        _buildFeatureCard(
                          icon: Icons.history_outlined,
                          title: 'Medical History',
                          description: 'Track your health journey with records',
                        ),
                        _buildFeatureCard(
                          icon: Icons.security_outlined,
                          title: 'Secure & Private',
                          description: 'Your data is protected with security',
                        ),
                      ],
                    ),
                  ],
                ),
              ),



              // Footer Section
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: lightGreyColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.phone_outlined,
                            color: primaryColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Need Help?',
                              style: TextStyle(
                                color: blackColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Hotline: 1900 1234',
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
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
    return loading
        ? const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
      ),
    )
        : Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: const Text(
          'Medical Diagnosis',
          style: TextStyle(
            color: whiteColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      backgroundColor: whiteColor,
      body: !widget.isLoggedIn
          ? _buildNotLoggedInUI()
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 30),
              const Center(
                child: Text(
                  'Upload Your Photo',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: whiteColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  side: const BorderSide(color: blackColor, width: 1),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: pickImageFromCamera,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt, color: blackColor),
                    SizedBox(width: 8),
                    Text(
                      'Take Photo',
                      style: TextStyle(
                        color: blackColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: whiteColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  side: const BorderSide(color: blackColor, width: 1),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: pickImageFromGallery,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image, color: blackColor),
                    SizedBox(width: 8),
                    Text(
                      'Pick From Gallery',
                      style: TextStyle(
                        color: blackColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => showInstructionsDialog(context),
                child: const Text(
                  'How to take a photo?',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (selectedFiles != null && selectedFiles!.isNotEmpty)
                const SizedBox(height: 20),
              if (selectedFiles != null && selectedFiles!.isNotEmpty)
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  alignment: WrapAlignment.center,
                  children: selectedFiles!
                      .map((file) => Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        File(file.path),
                        width: 150,
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ))
                      .toList(),
                ),
              const SizedBox(height: 20),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Describe your symptoms',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                maxLines: 4,
                onChanged: (value) => setState(() => symptoms = value),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: (selectedFiles != null &&
                    selectedFiles!.isNotEmpty &&
                    !isLoading)
                    ? handleSubmit
                    : null,
                child: isLoading
                    ? const SizedBox(
                  width: 24.0,
                  height: 24.0,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                        whiteColor),
                  ),
                )
                    : const Text(
                  'Diagnosis',
                  style: TextStyle(
                    color: whiteColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}