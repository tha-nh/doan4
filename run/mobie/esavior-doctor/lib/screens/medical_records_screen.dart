import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'PatientMedicalListScreen.dart';
import 'medical_record_detail_screen.dart';

class MedicalRecordsScreen extends StatefulWidget {
  const MedicalRecordsScreen({super.key, required this.doctorId});
  final int doctorId;

  @override
  State<MedicalRecordsScreen> createState() => _MedicalRecordsScreenState();
}

class _MedicalRecordsScreenState extends State<MedicalRecordsScreen>
    with SingleTickerProviderStateMixin {
  final _storage = const FlutterSecureStorage();
  List records = [];
  Map<String, List> groupedRecords = {}; // New: Group records by patient
  int? doctorId;
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';

  DateTime? startDate;
  DateTime? endDate;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Color palette
  static const Color primaryColor = Color(0xFF0288D1);
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color cardColor = Colors.white;
  static const Color errorColor = Color(0xFFE57373);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color textColor = Color(0xFF1A1A1A);

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadDoctorIdAndFetchRecords();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadDoctorIdAndFetchRecords() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String? idString = await _storage.read(key: 'doctor_id');
      if (idString != null) {
        setState(() {
          doctorId = int.tryParse(idString);
        });
        if (doctorId != null) {
          await fetchRecords();
          if (mounted) {
            _animationController.forward();
          }
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading information. Please try again!';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> fetchRecords() async {
    final url = Uri.parse('http://10.0.2.2:8081/api/v1/medicalrecords/doctor/$doctorId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> fetchedRecords = jsonDecode(response.body);
        print(fetchedRecords);
        final DateTime now = DateTime.now();
        final DateTime effectiveStartDate = startDate ?? now.subtract(const Duration(days: 30));
        final DateTime effectiveEndDate = endDate ?? now;

        // Filter records by date
        final filteredRecords = fetchedRecords.where((r) {
          final recordDate = DateTime.tryParse(r['follow_up_date'] ?? '') ?? DateTime(1970, 1, 1);
          return (recordDate.isAtSameMomentAs(effectiveStartDate) || recordDate.isAfter(effectiveStartDate)) &&
              (recordDate.isAtSameMomentAs(effectiveEndDate) || recordDate.isBefore(effectiveEndDate));
        }).toList();

        // Group records by patient
        _groupRecordsByPatient(filteredRecords);

        setState(() {
          records = filteredRecords;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = 'Error loading medical records list';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection error. Please try again!';
      });
    }
  }

  // New method to group records by patient
  void _groupRecordsByPatient(List<dynamic> records) {
    groupedRecords.clear();

    for (var record in records) {
      String patientKey = '';
      String patientName = '';

      // Get patient info
      if (record['patients'] != null && record['patients'].isNotEmpty) {
        patientName = record['patients'][0]['patient_name'] ?? '';
        String patientId = record['patients'][0]['patient_id']?.toString() ?? '';
        patientKey = '$patientId-$patientName';
      } else {
        patientKey = 'unknown-${record['patient_id'] ?? ''}';
        patientName = '';
      }

      if (!groupedRecords.containsKey(patientKey)) {
        groupedRecords[patientKey] = [];
      }

      groupedRecords[patientKey]!.add(record);
    }

    // Sort records within each patient group by date (newest first)
    groupedRecords.forEach((key, patientRecords) {
      patientRecords.sort((a, b) {
        final dateA = DateTime.tryParse(a['follow_up_date'] ?? '') ?? DateTime(1970, 1, 1);
        final dateB = DateTime.tryParse(b['follow_up_date'] ?? '') ?? DateTime(1970, 1, 1);
        return dateB.compareTo(dateA);
      });
    });
  }

  Map<String, List> _getFilteredGroupedRecords() {
    if (_searchQuery.isEmpty) {
      return groupedRecords;
    }

    Map<String, List> filtered = {};

    groupedRecords.forEach((patientKey, patientRecords) {
      List matchingRecords = patientRecords.where((record) {
        final matchesSearch =
            (record['patient_id']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
                (record['symptoms']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
                (record['diagnosis']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
                (patientKey.toLowerCase().contains(_searchQuery.toLowerCase()));

        return matchesSearch;
      }).toList();

      if (matchingRecords.isNotEmpty) {
        filtered[patientKey] = matchingRecords;
      }
    });

    return filtered;
  }

  Color _getSeverityColor(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'light':
        return successColor;
      case 'medium':
        return warningColor;
      case 'heavy':
        return Colors.deepOrange;
      case 'very heavy':
        return errorColor;
      default:
        return Colors.grey;
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              backgroundColor == successColor ? Icons.check_circle : Icons.info,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.lora(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingState()
            : _errorMessage != null
            ? _buildErrorState()
            : Column(
          children: [
            // _buildSearchBar(),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ListView(
                    children: [
                      _buildHeader(),
                      _buildFilters(),
                      _buildSearchBar(),
                      const SizedBox(height: 10),
                      _buildGroupedRecordsList(), // Updated method
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: primaryColor,
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading medical records...',
            style: GoogleFonts.lora(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: errorColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                color: errorColor,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! An error occurred',
              style: GoogleFonts.lora(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: GoogleFonts.lora(
                color: Colors.grey[600],
                fontSize: 16,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadDoctorIdAndFetchRecords,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              icon: const Icon(Icons.refresh, size: 20),
              label: Text(
                'Retry',
                style: GoogleFonts.lora(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor,
            primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.medical_information,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Medical Records',
                      style: GoogleFonts.lora(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Management and monitoring of medical records',
                      style: GoogleFonts.lora(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDateButton(
                  label: startDate == null ? 'From date' : DateFormat('dd/MM/yyyy').format(startDate!),
                  icon: Icons.calendar_today,
                  onPressed: () => _selectStartDate(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateButton(
                  label: endDate == null ? 'To date' : DateFormat('dd/MM/yyyy').format(endDate!),
                  icon: Icons.event,
                  onPressed: () => _selectEndDate(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: BorderSide(color: primaryColor.withOpacity(0.3)),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: GoogleFonts.lora(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search by patient name, symptoms, diagnosis...',
          hintStyle: GoogleFonts.lora(
            fontSize: 14,
            color: Colors.grey[500],
          ),
          prefixIcon: Icon(Icons.search, color: primaryColor),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            icon: Icon(Icons.clear, color: Colors.grey[500]),
            onPressed: () {
              setState(() {
                _searchQuery = '';
              });
            },
          )
              : null,
          filled: true,
          fillColor: cardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryColor, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        style: GoogleFonts.lora(
          fontSize: 14,
          color: textColor,
        ),

      ),
    );
  }

  // New method to build grouped records list
  Widget _buildGroupedRecordsList() {
    final filteredGroupedRecords = _getFilteredGroupedRecords();

    if (filteredGroupedRecords.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(

      onRefresh: fetchRecords,
      color: primaryColor,
      child: ListView.builder(

        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: filteredGroupedRecords.length,
        itemBuilder: (context, index) {
          final patientKey = filteredGroupedRecords.keys.elementAt(index);
          final patientRecords = filteredGroupedRecords[patientKey]!;
          return _buildPatientGroup(patientKey, patientRecords, index);
        },
      ),
    );
  }

  // New method to build patient group card
  Widget _buildPatientGroup(String patientKey, List patientRecords, int groupIndex) {
    final patientName = patientKey.split('-').length > 1
        ? patientKey.split('-').sublist(1).join('-')
        : '';
    final patientId = int.tryParse(patientKey.split('-')[0]) ?? 0;

    // 👇 Lấy ảnh bệnh nhân từ record đầu tiên
    final patientImg = patientRecords.isNotEmpty &&
        patientRecords[0]['patients'] != null &&
        patientRecords[0]['patients'].isNotEmpty
        ? patientRecords[0]['patients'][0]['patient_img']
        : null;

    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (groupIndex * 100)),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 10),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: patientImg != null
                ? Image.network(
              patientImg,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 48,
                height: 48,
                color: primaryColor.withOpacity(0.1),
                child: Icon(Icons.person, color: primaryColor),
              ),
            )
                : Container(
              width: 48,
              height: 48,
              color: primaryColor.withOpacity(0.1),
              child: Icon(Icons.person, color: primaryColor),
            ),
          ),
          title: Text(
            patientName,
            style: GoogleFonts.lora(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          subtitle: Text(
            'View medical record(s)',
            style: GoogleFonts.lora(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          trailing: Icon(Icons.arrow_forward_ios, color: primaryColor, size: 16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PatientMedicalListScreen(
                  patientId: patientId,
                  patientName: patientName,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off,
                color: Colors.grey[400],
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No records found',
              style: GoogleFonts.lora(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try changing your search filters or keywords',
              style: GoogleFonts.lora(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordDetail({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.grey[600], size: 14),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.lora(
                  fontSize: 10,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.lora(
                  fontSize: 12,
                  color: textColor,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: textColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        startDate = picked;
      });
      await fetchRecords();
      _showSnackBar('Start date updated', successColor);
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: endDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: textColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        endDate = picked;
      });
      await fetchRecords();
      _showSnackBar('End date updated', successColor);
    }
  }
}