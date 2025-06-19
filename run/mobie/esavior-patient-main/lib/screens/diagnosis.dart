import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

const primaryColor = Colors.blue;
const whiteColor = Color.fromARGB(255, 255, 255, 255);
const blackColor = Color.fromARGB(255, 0, 0, 0);
const blueColor = Color.fromARGB(255, 33, 150, 233);

class Diagnosis extends StatefulWidget {
  final bool isLoggedIn;
  final Function onLogout;
  final int? patientId;

  Diagnosis({required this.isLoggedIn, required this.onLogout, this.patientId});

  @override
  _DiagnosisState createState() => _DiagnosisState();
}

class _DiagnosisState extends State<Diagnosis> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<XFile>? selectedFiles = [];
  bool loading = false;
  bool isLoading = false;
  String fullText = '';
  String comparisonMessage = '';
  double severity = 0.0;
  List medicalHistory = [];
  String symptoms = '';

  @override
  void initState() {
    super.initState();
    if (widget.patientId == null || !widget.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
    } else {
      loadMedicalHistory();
    }
  }

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
      request.files.add(await http.MultipartFile.fromPath('files', file.path)); // Sử dụng 'files'
      print('Added file: ${file.path}');
    }
    request.fields['symptoms'] = symptoms;
    print('Sending symptoms: $symptoms');
    print('Request fields: ${request.fields}');
    print('Request files: ${request.files.map((f) => f.field).toList()}');

    setState(() {
      isLoading = true;
      fullText = '';
    });
    print('Starting prediction request to $uri');

    try {
      final response = await request.send();
      print('Response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        print('API Response: $responseData');
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
          print('JSON parse error: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid response from server')),
          );
        }
      } else {
        final errorData = await response.stream.bytesToString();
        print('API error: ${response.statusCode} - $errorData');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server error: ${response.statusCode} - $errorData')),
        );
      }
    } catch (e) {
      print('Prediction error: $e');
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
      print('Save response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        print('Medical record saved successfully');
      } else {
        print('Save error: ${response.statusCode} - ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save error: ${response.statusCode} - ${response.body}')),
        );
      }
    } catch (e) {
      print('Save error: $e');
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
    print('Dialog: fullText=$fullText, comparisonMessage=$comparisonMessage');
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

  @override
  Widget build(BuildContext context) {
    return loading
        ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(primaryColor)))
        : Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Center(child: Text('Diagnostic Imaging', style: TextStyle(color: whiteColor, fontWeight: FontWeight.bold, fontSize: 20))),
      ),
      backgroundColor: whiteColor,
      body: SingleChildScrollView(
        child: !widget.isLoggedIn
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: double.infinity, height: 300, decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('assets/images/3824251.jpg'), fit: BoxFit.cover))),
            const SizedBox(height: 60),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Expanded(child: Text('Sign in for full access', textAlign: TextAlign.left, style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: blackColor))),
                  const SizedBox(width: 30),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                    style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.all(20), backgroundColor: primaryColor, elevation: 5),
                    child: const Icon(Icons.arrow_forward, color: whiteColor, size: 24),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 150),
            const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.phone_outlined, color: blackColor, size: 20),
                  SizedBox(width: 10),
                  Text('Hotline:', style: TextStyle(color: blackColor, fontSize: 14, fontWeight: FontWeight.bold)),
                  SizedBox(width: 5),
                  Text('1900 1234', style: TextStyle(color: primaryColor, fontSize: 16, fontWeight: FontWeight.bold)),
                ]),
                Center(child: Text('Version: 1.0.0', style: TextStyle(color: Colors.black54, fontSize: 14, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic))),
                SizedBox(height: 50),
              ],
            ),
          ],
        )
            : Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 30),
              const Center(child: Text('Upload Your Photo', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryColor))),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: whiteColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), side: const BorderSide(color: blackColor, width: 1), padding: const EdgeInsets.symmetric(vertical: 15)),
                onPressed: pickImageFromCamera,
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.camera_alt, color: blackColor), SizedBox(width: 8), Text('Take Photo', style: TextStyle(color: blackColor, fontSize: 16, fontWeight: FontWeight.bold))]),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: whiteColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), side: const BorderSide(color: blackColor, width: 1), padding: const EdgeInsets.symmetric(vertical: 15)),
                onPressed: pickImageFromGallery,
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.image, color: blackColor), SizedBox(width: 8), Text('Pick From Gallery', style: TextStyle(color: blackColor, fontSize: 16, fontWeight: FontWeight.bold))]),
              ),
              TextButton(onPressed: () => showInstructionsDialog(context), child: const Text('How to take a photo?', style: TextStyle(color: Colors.black54, fontSize: 14, fontWeight: FontWeight.bold))),

              if (selectedFiles != null && selectedFiles!.isNotEmpty) const SizedBox(height: 20),
              if (selectedFiles != null && selectedFiles!.isNotEmpty)
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  alignment: WrapAlignment.center,
                  children: selectedFiles!.map((file) => Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(File(file.path), width: 150, height: 150, fit: BoxFit.cover),
                    ),
                  )).toList(),
                ),
              const SizedBox(height: 20),
              TextFormField(
                decoration: InputDecoration(labelText: 'Describe your symptoms', border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
                maxLines: 4,
                onChanged: (value) => setState(() => symptoms = value),
              ),

              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), padding: const EdgeInsets.symmetric(vertical: 15)),
                onPressed: (selectedFiles != null && selectedFiles!.isNotEmpty && !isLoading) ? handleSubmit : null,
                child: isLoading
                    ? const SizedBox(width: 24.0, height: 24.0, child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(primaryColor)))
                    : const Text('Diagnosis', style: TextStyle(color: whiteColor, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}