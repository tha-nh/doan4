import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const primaryColor = Colors.blue;
const whiteColor = Color.fromARGB(255, 255, 255, 255);
const blackColor = Color.fromARGB(255, 0, 0, 0);
const blueColor = Color.fromARGB(255, 33, 150, 233);

class MedicalRecords extends StatefulWidget {
  final bool isLoggedIn;
  final Function onLogout;
  final int? patientId;

  MedicalRecords({
    required this.isLoggedIn,
    required this.onLogout,
    this.patientId,
  });

  @override
  _MedicalRecordsState createState() => _MedicalRecordsState();
}

class _MedicalRecordsState extends State<MedicalRecords> {
  List<dynamic> medicalRecords = [];
  List<dynamic> allMedicalRecords = []; // Store all records
  int currentPage = 0;
  int medicalRecordsPerPage = 5;
  bool isLoading = false;

  // Filter variables
  DateTime? startDate;
  DateTime? endDate;
  bool showFilters = false;
  bool isDefaultView = true;

  @override
  void initState() {
    super.initState();
    fetchPatientData();
  }

  // Fetch patient data
  Future<void> fetchPatientData() async {
    setState(() {
      isLoading = true;
    });
    final url = Uri.parse(
        'http://10.0.2.2:8081/api/v1/patients/search?patient_id=${widget.patientId}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        var patientData = json.decode(response.body);
        if (patientData.isNotEmpty) {
          List<dynamic> fetchedRecords = patientData[0]['medicalrecordsList'] ?? [];

          setState(() {
            allMedicalRecords = fetchedRecords;
          });

          // Apply default sorting (newest first)
          applyDefaultFilter();
        }
      } else {
        print('Error fetching patient data! Status Code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error: $error');
    }
    setState(() {
      isLoading = false;
    });
  }

  // Apply default filter (all records, sorted by date)
  void applyDefaultFilter() {
    List<dynamic> sortedRecords = List.from(allMedicalRecords);

    // Sort by follow_up_date (newest first)
    sortedRecords.sort((a, b) {
      try {
        DateTime dateA = DateTime.parse(a['follow_up_date']);
        DateTime dateB = DateTime.parse(b['follow_up_date']);
        return dateB.compareTo(dateA);
      } catch (e) {
        print('Error sorting records: $e');
        return 0;
      }
    });

    setState(() {
      medicalRecords = sortedRecords;
      currentPage = 0;
    });
  }

  // Apply date range filters
  void applyFilters() {
    List<dynamic> filteredRecords = List.from(allMedicalRecords);

    // Filter by date range
    if (startDate != null || endDate != null) {
      filteredRecords = filteredRecords.where((record) {
        String followUpDateStr = record['follow_up_date'] ?? '';
        if (followUpDateStr.isEmpty) return false;

        try {
          DateTime followUpDate = DateTime.parse(followUpDateStr);
          DateTime followUpDateOnly = DateTime(followUpDate.year, followUpDate.month, followUpDate.day);

          bool afterStart = startDate == null || followUpDateOnly.isAtSameMomentAs(startDate!) || followUpDateOnly.isAfter(startDate!);
          bool beforeEnd = endDate == null || followUpDateOnly.isAtSameMomentAs(endDate!) || followUpDateOnly.isBefore(endDate!);

          return afterStart && beforeEnd;
        } catch (e) {
          print('Error parsing follow_up_date: $followUpDateStr');
          return false;
        }
      }).toList();
    }

    // Sort filtered records
    filteredRecords.sort((a, b) {
      try {
        DateTime dateA = DateTime.parse(a['follow_up_date']);
        DateTime dateB = DateTime.parse(b['follow_up_date']);
        return dateB.compareTo(dateA);
      } catch (e) {
        print('Error sorting filtered records: $e');
        return 0;
      }
    });

    setState(() {
      medicalRecords = filteredRecords;
      currentPage = 0;
      isDefaultView = false;
    });
  }

  // Reset to default view
  void resetToDefault() {
    setState(() {
      startDate = null;
      endDate = null;
      isDefaultView = true;
    });
    applyDefaultFilter();
  }

  // Date picker helper
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? startDate ?? DateTime.now() : endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }

  Widget buildFilterSection() {
    if (!showFilters) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filter by Date Range',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              if (!isDefaultView)
                TextButton.icon(
                  onPressed: resetToDefault,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Reset'),
                  style: TextButton.styleFrom(
                    foregroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Date Range Selection
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('From Date:', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () => _selectDate(context, true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[400]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              startDate != null
                                  ? '${startDate!.day}/${startDate!.month}/${startDate!.year}'
                                  : 'Select date',
                              style: TextStyle(
                                color: startDate != null ? Colors.black : Colors.grey[600],
                              ),
                            ),
                            const Icon(Icons.calendar_today, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('To Date:', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () => _selectDate(context, false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[400]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              endDate != null
                                  ? '${endDate!.day}/${endDate!.month}/${endDate!.year}'
                                  : 'Select date',
                              style: TextStyle(
                                color: endDate != null ? Colors.black : Colors.grey[600],
                              ),
                            ),
                            const Icon(Icons.calendar_today, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Apply Filter Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: applyFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: whiteColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Apply Date Filter'),
            ),
          ),
        ],
      ),
    );
  }

  List<dynamic> getPaginatedMedicalRecords() {
    int startIndex = currentPage * medicalRecordsPerPage;
    int endIndex = (startIndex + medicalRecordsPerPage).clamp(0, medicalRecords.length);
    return medicalRecords.sublist(startIndex, endIndex);
  }

  Widget buildMedicalRecords() {
    var paginatedMedicalRecords = getPaginatedMedicalRecords();

    return ListView.builder(
      itemCount: paginatedMedicalRecords.length,
      itemBuilder: (context, index) {
        var record = paginatedMedicalRecords[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
            side: const BorderSide(
              color: Colors.black54,
              width: 1,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: whiteColor,
              borderRadius: BorderRadius.circular(15.0),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${record['follow_up_date']}",
                        style: const TextStyle(
                            fontSize: 18,
                            color: primaryColor,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Symptoms: ${record['symptoms'] ?? 'Hollow'}",
                        style: const TextStyle(
                            fontSize: 16,
                            color: blackColor,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Diagnosis: ${record['diagnosis'] ?? 'Healthy'}",
                        style: const TextStyle(
                            fontSize: 16,
                            color: blackColor,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Treatment: ${record['treatment'] ?? 'Normal'}",
                        style: const TextStyle(
                            fontSize: 16,
                            color: blackColor,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Precription: ${record['precription'] ?? 'No medicine needed'}",
                        style: const TextStyle(
                            fontSize: 16,
                            color: blackColor,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildPaginationControls() {
    int totalPages = (medicalRecords.length / medicalRecordsPerPage).ceil();
    if (totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.black54,
            ),
            onPressed: currentPage > 0
                ? () {
              setState(() {
                currentPage--;
              });
            }
                : null,
          ),
          Text(
            'Page ${currentPage + 1} of $totalPages',
            style: const TextStyle(
                color: primaryColor, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          IconButton(
            icon: const Icon(
              Icons.arrow_forward,
              color: Colors.black54,
            ),
            onPressed: currentPage < totalPages - 1
                ? () {
              setState(() {
                currentPage++;
              });
            }
                : null,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoggedIn) {
      Future.delayed(Duration.zero, () {
        Navigator.pushReplacementNamed(context, '/login');
      });
    }
    return Scaffold(
      backgroundColor: whiteColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: whiteColor,
            size: 25,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(
              showFilters ? Icons.filter_list_off : Icons.filter_list,
              color: whiteColor,
              size: 25,
            ),
            onPressed: () {
              setState(() {
                showFilters = !showFilters;
              });
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
        ),
      )
          : Column(
        children: [
          const SizedBox(height: 30),
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: whiteColor,
            ),
            child: const Center(
              child: Text(
                'Medical Records',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: primaryColor,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Filter Section
          buildFilterSection(),

          Container(
            height: 10,
            color: primaryColor.withOpacity(0.05),
          ),
          const SizedBox(height: 10),
          medicalRecords.isEmpty
              ? Expanded(
              child: Center(
                child: Text(
                  isDefaultView
                      ? 'No medical record available'
                      : 'No medical records found for selected date range',
                  style: const TextStyle(
                      color: blackColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
              ))
              : Expanded(
            child: buildMedicalRecords(),
          ),
          buildPaginationControls(),
        ],
      ),
    );
  }
}