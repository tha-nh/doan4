import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'appointment_details_screen.dart'; // Import the details screen

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key, required this.doctorId});
  final int doctorId;

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> with SingleTickerProviderStateMixin {
  final _storage = const FlutterSecureStorage();
  List appointments = [];
  int? _doctorId;
  bool _isLoading = true;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  // Search criteria
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedStatus;

  // Color palette to match AppointmentDetailsScreen
  static const Color primaryColor = Color(0xFF0288D1);
  static const Color accentColor = Color(0xFFFFB300);
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color cardColor = Colors.white;
  static const Color errorColor = Color(0xFFE57373);
  static const Color textColor = Color(0xFF1A1A1A);

  @override
  void initState() {
    super.initState();
    // Initialize animation controller and slide animation
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
    // Start animation only after initialization
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
      _errorMessage = null;
    });
    final idString = await _storage.read(key: 'doctor_id');
    if (idString != null) {
      setState(() {
        _doctorId = int.tryParse(idString);
      });
      if (_doctorId != null) {
        await fetchAppointments();
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> fetchAppointments({String? startDate, String? endDate, String? status}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Construct query parameters
    final Map<String, String> queryParams = {};
    if (_doctorId != null) {
      queryParams['doctor_id'] = _doctorId.toString();
    }
    if (startDate != null) {
      queryParams['start_date'] = startDate;
    }
    if (endDate != null) {
      queryParams['end_date'] = endDate;
    }
    if (status != null) {
      queryParams['status'] = status;
    }

    final url = Uri.http('10.0.2.2:8081', '/api/v1/appointments/searchByCriteriaAndDoctor', queryParams);

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          appointments = jsonDecode(response.body);
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = 'Lỗi khi tải danh sách lịch hẹn: ${response.statusCode}';
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

  String _formatDate(String? date) {
    if (date == null) return 'Chưa xác định';
    try {
      final parsedDate = DateTime.parse(date);
      return DateFormat('dd/MM/yyyy').format(parsedDate);
    } catch (e) {
      return date;
    }
  }

  // Show search dialog
  void _showSearchDialog() {
    final TextEditingController startDateController = TextEditingController(
      text: _startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : '',
    );
    final TextEditingController endDateController = TextEditingController(
      text: _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : '',
    );
    String? tempStatus = _selectedStatus;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'Tìm kiếm lịch hẹn',
                style: GoogleFonts.lora(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Start Date Picker
                    TextField(
                      controller: startDateController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Ngày bắt đầu',
                        labelStyle: GoogleFonts.lora(color: Colors.black54),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today, color: primaryColor),
                          onPressed: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: _startDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              setDialogState(() {
                                _startDate = picked;
                                startDateController.text = DateFormat('yyyy-MM-dd').format(picked);
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // End Date Picker
                    TextField(
                      controller: endDateController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Ngày kết thúc',
                        labelStyle: GoogleFonts.lora(color: Colors.black54),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today, color: primaryColor),
                          onPressed: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: _endDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              setDialogState(() {
                                _endDate = picked;
                                endDateController.text = DateFormat('yyyy-MM-dd').format(picked);
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Status Dropdown
                    DropdownButtonFormField<String>(
                      value: tempStatus,
                      decoration: InputDecoration(
                        labelText: 'Trạng thái',
                        labelStyle: GoogleFonts.lora(color: Colors.black54),
                      ),
                      items: ['PENDING', 'CONFIRMED', 'CANCELLED'].map((status) {
                        return DropdownMenuItem<String>(
                          value: status,
                          child: Text(status, style: GoogleFonts.lora()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          tempStatus = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _startDate = null;
                      _endDate = null;
                      _selectedStatus = null;
                    });
                    startDateController.clear();
                    endDateController.clear();
                    Navigator.pop(context);
                    fetchAppointments(); // Reset to default fetch
                  },
                  child: Text(
                    'Xóa bộ lọc',
                    style: GoogleFonts.lora(color: errorColor),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedStatus = tempStatus;
                    });
                    Navigator.pop(context);
                    fetchAppointments(
                      startDate: _startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : null,
                      endDate: _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : null,
                      status: _selectedStatus,
                    );
                  },
                  child: Text(
                    'Tìm kiếm',
                    style: GoogleFonts.lora(color: primaryColor),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Define the start of today (00:00 on May 28, 2025)
    final todayStart = DateTime(2025, 5, 28, 0, 0, 0);

    // Filter and sort appointments
    final pendingAppointments = appointments.where((a) {
      final isPending = a['status'] == 'PENDING';
      if (!isPending && _selectedStatus == null) return false;
      final medicalDay = a['medical_day'];
      if (medicalDay == null) return false;
      try {
        final parsedMedicalDay = DateTime.parse(medicalDay);
        return parsedMedicalDay.isAfter(todayStart) || parsedMedicalDay.isAtSameMomentAs(todayStart);
      } catch (e) {
        return false;
      }
    }).toList();

    // Sort appointments by medical_day and slot
    pendingAppointments.sort((a, b) {
      final dateA = a['medical_day'] != null ? DateTime.parse(a['medical_day']) : DateTime(1970);
      final dateB = b['medical_day'] != null ? DateTime.parse(b['medical_day']) : DateTime(1970);
      final dateComparison = dateA.compareTo(dateB);
      if (dateComparison == 0) {
        final slotA = a['slot'] ?? '';
        final slotB = b['slot'] ?? '';
        return slotA.compareTo(slotB);
      }
      return dateComparison;
    });

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,

        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: _showSearchDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(
          child: CircularProgressIndicator(
            color: accentColor,
            strokeWidth: 4,
          ),
        )
            : _errorMessage != null
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: errorColor,
                size: 60,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: GoogleFonts.lora(
                  color: errorColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadDoctorIdAndFetch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                ),
                icon: const Icon(Icons.refresh, size: 20),
                label: Text(
                  'Thử lại',
                  style: GoogleFonts.lora(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        )
            : pendingAppointments.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.event_busy,
                color: Colors.grey[500],
                size: 60,
              ),
              const SizedBox(height: 16),
              Text(
                'Không có lịch hẹn đang chờ xử lý',
                style: GoogleFonts.lora(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        )
            : RefreshIndicator(
          onRefresh: () => fetchAppointments(
            startDate: _startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : null,
            endDate: _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : null,
            status: _selectedStatus,
          ),
          color: accentColor,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pendingAppointments.length,
            itemBuilder: (context, index) {
              final a = pendingAppointments[index];
              final patientName = a['patient'] != null && a['patient'].isNotEmpty
                  ? a['patient'][0]['patient_name'] ?? 'Bệnh nhân ID: ${a['patient_id']}'
                  : 'Bệnh nhân ID: ${a['patient_id'] ?? 'Không xác định'}';

              return SlideTransition(
                position: _slideAnimation,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
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
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AppointmentDetailsScreen(appointment: a),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: primaryColor.withOpacity(0.2),
                            child: const Icon(
                              Icons.event,
                              color: primaryColor,
                              size: 40,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  patientName,
                                  style: GoogleFonts.lora(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Ngày: ${_formatDate(a['medical_day'])}',
                                  style: GoogleFonts.lora(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                                Text(
                                  'Khung giờ: ${a['slot'] ?? 'Chưa xác định'}',
                                  style: GoogleFonts.lora(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.grey[400],
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}