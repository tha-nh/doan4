import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:google_fonts/google_fonts.dart';

import '../service/appointment_service.dart';
import 'appointment_details_screen.dart';
import 'dart:math' as math;

class PastAppointmentsScreen extends StatefulWidget {
  const PastAppointmentsScreen({super.key, required this.doctorId});
  final int doctorId;

  @override
  State<PastAppointmentsScreen> createState() => _PastAppointmentsScreenState();
}

class _PastAppointmentsScreenState extends State<PastAppointmentsScreen>
    with TickerProviderStateMixin {
  final _appointmentService = OptimizedAppointmentService();

  List<Map<String, dynamic>> pastAppointments = [];
  List<Map<String, dynamic>> filteredAppointments = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isLocaleInitialized = false;
  bool _isRefreshing = false;

  // Date filter variables
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _isFilterExpanded = false;

  late AnimationController _mainAnimationController;
  late AnimationController _filterAnimationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _filterAnimation;

  static const Color primaryColor = Color(0xFF2196F3);
  static const Color primaryDarkColor = Color(0xFF1976D2);
  static const Color accentColor = Color(0xFFFF9800);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color cardColor = Colors.white;
  static const Color errorColor = Color(0xFFE57373);
  static const Color successColor = Color(0xFF66BB6A);
  static const Color textColor = Color(0xFF1A1A1A);
  static const Color textSecondaryColor = Color(0xFF64748B);
  static const Color shadowColor = Color(0x1A000000);

  @override
  void initState() {
    super.initState();

    // Initialize default date range (last 15 days)
    final now = DateTime.now();
    _toDate = DateTime(now.year, now.month, now.day);
    _fromDate = _toDate!.subtract(const Duration(days: 15));

    _mainAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _filterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: Curves.easeInOut,
    ));

    _filterAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _filterAnimationController,
      curve: Curves.easeInOut,
    ));

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _initializeDateFormatting();
    await _fetchPastAppointments();
    if (mounted) {
      _mainAnimationController.forward();
    }
  }

  Future<void> _initializeDateFormatting() async {
    try {
      await initializeDateFormatting('vi', null);
      _isLocaleInitialized = true;
    } catch (e) {
      _isLocaleInitialized = false;
    }
  }

  @override
  void dispose() {
    _mainAnimationController.dispose();
    _filterAnimationController.dispose();
    super.dispose();
  }

  Future<void> _fetchPastAppointments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final fetchedAppointments = await _appointmentService.fetchPastAppointments(widget.doctorId);
      setState(() {
        pastAppointments = fetchedAppointments;
        _errorMessage = null;
        _applyDateFilter();
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyDateFilter() {
    if (_fromDate == null || _toDate == null) {
      filteredAppointments = pastAppointments;
      return;
    }

    filteredAppointments = pastAppointments.where((appointment) {
      final medicalDayStr = appointment['medical_day']?.toString();
      if (medicalDayStr == null) return false;

      try {
        final medicalDay = DateTime.parse(medicalDayStr);
        final appointmentDate = DateTime(medicalDay.year, medicalDay.month, medicalDay.day);

        return appointmentDate.isAfter(_fromDate!.subtract(const Duration(days: 1))) &&
            appointmentDate.isBefore(_toDate!.add(const Duration(days: 1)));
      } catch (e) {
        return false;
      }
    }).toList();
  }

  Future<void> _refreshPastAppointments() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      await _fetchPastAppointments();
    } catch (e) {
      _showSnackBar('Lỗi khi cập nhật: $e', errorColor);
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.lora(color: Colors.white),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now().subtract(const Duration(days: 15)),
      firstDate: DateTime(2020),
      lastDate: _toDate ?? DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
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
        _fromDate = picked;
        _applyDateFilter();
      });
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? DateTime.now(),
      firstDate: _fromDate ?? DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
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
        _toDate = picked;
        _applyDateFilter();
      });
    }
  }

  void _clearFilter() {
    setState(() {
      _fromDate = null;
      _toDate = null;
      filteredAppointments = pastAppointments;
    });
  }

  void _toggleFilterExpansion() {
    setState(() {
      _isFilterExpanded = !_isFilterExpanded;
    });

    if (_isFilterExpanded) {
      _filterAnimationController.forward();
    } else {
      _filterAnimationController.reverse();
    }
  }

  String _formatDateVerbose(String? date) {
    if (date == null) return 'Chưa xác định';
    try {
      final parsedDate = DateTime.parse(date);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final appointmentDate = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);

      if (appointmentDate.isAtSameMomentAs(today)) {
        return 'Hôm nay';
      } else if (appointmentDate.isAtSameMomentAs(yesterday)) {
        return 'Hôm qua';
      } else {
        final difference = today.difference(appointmentDate).inDays;
        if (difference <= 7) {
          return '$difference ngày trước';
        } else if (_isLocaleInitialized) {
          return DateFormat('EEEE, dd/MM/yyyy', 'vi').format(parsedDate);
        } else {
          return DateFormat('dd/MM/yyyy').format(parsedDate);
        }
      }
    } catch (e) {
      return date;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Chọn ngày';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String _getStatusText(String? status) {
    switch (status?.toUpperCase()) {
      case 'CONFIRMED':
        return 'CONFIRMED';
      case 'CANCELLED':
        return 'CANCELLED';
      case 'PENDING':
        return 'PENDING';
      default:
        return 'ERROR';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'CONFIRMED':
        return successColor;
      case 'CANCELLED':
        return errorColor;
      case 'PENDING':
        return accentColor;
      default:
        return textSecondaryColor;
    }
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor,
            primaryDarkColor,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lịch Sử Khám Bệnh',
                        style: GoogleFonts.lora(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Các cuộc hẹn đã qua',
                        style: GoogleFonts.lora(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _toggleFilterExpansion,
                  icon: Icon(
                    _isFilterExpanded ? Icons.filter_list_off : Icons.filter_list,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return AnimatedBuilder(
      animation: _filterAnimation,
      builder: (context, child) {
        return Container(
          height: _filterAnimation.value * 190,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lọc theo ngày khám',
                    style: GoogleFonts.lora(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _selectStartDate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.calendar_today, size: 18),
                          label: Text(
                            _formatDate(_fromDate),
                            style: GoogleFonts.lora(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _selectEndDate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.calendar_today, size: 18),
                          label: Text(
                            _formatDate(_toDate),
                            style: GoogleFonts.lora(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _clearFilter,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade100,
                            foregroundColor: textColor,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Xóa lọc',
                            style: GoogleFonts.lora(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_fromDate != null && _toDate != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Hiển thị ${filteredAppointments.length} cuộc hẹn',
                      style: GoogleFonts.lora(
                        fontSize: 12,
                        color: textSecondaryColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment, int index) {
    final patientList = appointment['patient'] as List<dynamic>?;
    final patientName = patientList != null && patientList.isNotEmpty
        ? (patientList[0] as Map<String, dynamic>)['patient_name']?.toString() ??
        'Bệnh nhân ID: ${appointment['patient_id']}'
        : 'Bệnh nhân ID: ${appointment['patient_id'] ?? 'Không xác định'}';

    final timeSlot = _appointmentService.getTimeSlot(appointment['slot']);
    final appointmentDate = _formatDateVerbose(appointment['medical_day']?.toString());
    final status = appointment['status']?.toString();
    final statusText = _getStatusText(status);
    final statusColor = _getStatusColor(status);

    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _fadeAnimation.value) * 30),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: Colors.grey.shade100,
                  width: 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            AppointmentDetailsScreen(appointment: appointment),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(1.0, 0.0),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            )),
                            child: child,
                          );
                        },
                        transitionDuration: const Duration(milliseconds: 300),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [primaryColor, primaryDarkColor],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.person,
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
                                    patientName,
                                    style: GoogleFonts.lora(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: textColor,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'ID: ${appointment['patient_id']}',
                                    style: GoogleFonts.lora(
                                      fontSize: 12,
                                      color: textSecondaryColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: statusColor.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                statusText,
                                style: GoogleFonts.lora(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildInfoItem(
                                  Icons.calendar_today,
                                  'Ngày khám',
                                  appointmentDate,
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: Colors.grey.shade300,
                                margin: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                              Expanded(
                                child: _buildInfoItem(
                                  Icons.access_time,
                                  'Giờ khám',
                                  timeSlot,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: primaryColor,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.lora(
                  fontSize: 11,
                  color: textSecondaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.lora(
                  fontSize: 13,
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.history_outlined,
              size: 64,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _fromDate != null && _toDate != null
                ? 'Không có lịch hẹn trong khoảng thời gian này'
                : 'Chưa có lịch sử khám bệnh',
            style: GoogleFonts.lora(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _fromDate != null && _toDate != null
                ? 'Thử chọn khoảng thời gian khác'
                : 'Các cuộc hẹn đã hoàn thành sẽ hiển thị ở đây',
            style: GoogleFonts.lora(
              fontSize: 14,
              color: textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: errorColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              size: 64,
              color: errorColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Có lỗi xảy ra',
            style: GoogleFonts.lora(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: GoogleFonts.lora(
              fontSize: 14,
              color: textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchPastAppointments,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          SizedBox(
            height: 140,
            child: _buildHeader(),
          ),
          if (_isFilterExpanded) _buildFilterSection(),
          Expanded(
            child: _isLoading
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: primaryColor,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Đang tải lịch sử...',
                    style: GoogleFonts.lora(
                      fontSize: 16,
                      color: textSecondaryColor,
                    ),
                  ),
                ],
              ),
            )
                : _errorMessage != null
                ? _buildErrorState()
                : filteredAppointments.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
              onRefresh: _refreshPastAppointments,
              color: primaryColor,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredAppointments.length,
                itemBuilder: (context, index) {
                  return _buildAppointmentCard(
                    filteredAppointments[index],
                    index,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}