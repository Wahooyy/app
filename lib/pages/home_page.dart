// lib/pages/home_page.dart
// ignore_for_file: deprecated_member_use, use_build_context_synchronously, unnecessary_brace_in_string_interps, avoid_print, use_key_in_widget_constructors, library_private_types_in_public_api

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import '../services/face_recognition_service.dart';
import '../services/auth_service.dart';
import 'attendance_history.dart';
import 'profile.dart';
import 'ticket_support_page.dart';
import 'face_registration_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final Color _primaryColor = Color(0xFF143CFF);
  final List<GlobalKey<_ScaleIconState>> _iconKeys = List.generate(
    4,
    (_) => GlobalKey<_ScaleIconState>(),
  );
  // ignore: unused_field
  bool _isLoading = false;
  // ignore: unused_field
  bool _isLoadingProfile = true;
  bool _checkedInToday = false;
  String? _jamIn;
  bool _checkedOutToday = false;
  String? _jamOut;
  bool _loadingCheckinStatus = true;
  List<Map<String, dynamic>> _recentAttendance = [];

  Map<String, dynamic> _userData = {
    'adminname': '',
    'username': '',
    'nip': '',
    'email': '',
    'address': '',
  };

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  // Track the selected attendance tab (check-in or check-out)
  String _selectedAttendanceTab = 'Masuk';

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserProfile();
      _loadCheckinStatus();
      fetchRecentAttendance();
    });
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoadingProfile = true;
    });

    try {
      // Check if user is logged in
      final userId = AuthService.getUserId();
      if (userId == null) {
        _showMessage('You are not logged in. Please log in again.');
        setState(() {
          _isLoadingProfile = false;
        });
        // Redirect to login
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      final userData = await AuthService.getUserProfile();

      if (userData != null) {
        setState(() {
          _userData = userData;
          _nameController.text = _userData['adminname'] ?? '';
          _emailController.text = _userData['email'] ?? '';
          _phoneController.text = _userData['nip'] ?? '';
          _addressController.text = _userData['location'] ?? '';
          _isLoadingProfile = false;
        });
      } else {
        _showMessage('Could not retrieve profile data. Please try again.');
        setState(() {
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      print('Error loading profile: $e');
      _showMessage('Error: $e');
      setState(() {
        _isLoadingProfile = false;
      });
    }
  }

  Future<void> _loadCheckinStatus() async {
    setState(() {
      _loadingCheckinStatus = true;
    });
    final status = await AuthService.getTodayCheckinStatus();
    setState(() {
      _checkedInToday = status['checked_in'] ?? false;
      _jamIn = status['jam_in'];
      _checkedOutToday = status['checked_out'] ?? false;
      _jamOut = status['jam_out'];
      _loadingCheckinStatus = false;
      print('Checked out today: $_checkedOutToday');
    });
  }

  Future<void> fetchRecentAttendance() async {
    final userId = AuthService.getUserId();
    if (userId == null) {
      // Handle the null case appropriately, e.g., show a message or return early
      return;
    }
    final data = await AuthService.getLatestAttendance(userId);

    // Format ulang agar cocok sama widget ListTile
    setState(() {
      _recentAttendance =
          data.map((item) {
            return {
              'date': DateTime.parse(item['tgl_absen']),
              'clockIn': item['jam_in'] ?? '-',
              'clockOut': item['jam_out'] ?? '-',
              'status': _capitalize(item['status']),
            };
          }).toList();
    });
  }

  String _capitalize(String input) {
    if (input.isEmpty) return '';
    return input[0].toUpperCase() + input.substring(1);
  }

  // Add this function to your _HomePageState class
  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            shape: SmoothRectangleBorder(
              borderRadius: SmoothBorderRadius(
                cornerRadius: 20,
                cornerSmoothing: 1,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 20),
                CircularProgressIndicator(color: _primaryColor, strokeWidth: 3),
                SizedBox(height: 24),
                Text(
                  "Memproses...",
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
    );
  }

  void _showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: SmoothRectangleBorder(
              borderRadius: SmoothBorderRadius(
                cornerRadius: 20,
                cornerSmoothing: 1,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 20),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      HugeIcons.strokeRoundedCheckmarkCircle03,
                      color: Colors.green,
                      size: 50,
                    ),
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  message,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: SmoothRectangleBorder(
                        borderRadius: SmoothBorderRadius(
                          cornerRadius: 12,
                          cornerSmoothing: 0.8,
                        ),
                      ),
                    ),
                    child: Text(
                      "OK",
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: SmoothRectangleBorder(
              borderRadius: SmoothBorderRadius(
                cornerRadius: 20,
                cornerSmoothing: 1,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 20),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      HugeIcons.strokeRoundedAlert01,
                      color: Colors.red,
                      size: 50,
                    ),
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  "Error",
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),
                Text(
                  message,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: SmoothRectangleBorder(
                        borderRadius: SmoothBorderRadius(
                          cornerRadius: 12,
                          cornerSmoothing: 0.8,
                        ),
                      ),
                    ),
                    child: Text(
                      "OK",
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _startAttendanceFlow() async {
    // Check if already loading
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      // Step 1: Show QR code scanner
      final scannedCode = await showDialog<String>(
        context: context,
        builder: (context) => QRScanDialog(),
      );

      if (scannedCode == null || scannedCode.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      // Show loading dialog while preparing face capture
      _showLoadingDialog(context);

      try {
        // Get current user ID - replace with your actual user ID retrieval
        final userId = AuthService.getUserId();

        if (userId == null) {
          Navigator.of(context).pop(); // Close loading dialog
          setState(() => _isLoading = false);
          _showMessage('User not logged in');
          return;
        }

        // Get the face embedding from the server
        final faceEmbedding = await AuthService.getUserFaceEmbedding(userId);
        print('Face embedding: $faceEmbedding');

        if (!mounted) return;
        Navigator.of(context).pop();

        if (faceEmbedding == null) {
          setState(() => _isLoading = false);
          // Show dialog to register face first
          final shouldRegister = await showDialog<bool>(
            context: context,
            builder:
                (context) => AlertDialog(
                  shape: SmoothRectangleBorder(
                    borderRadius: SmoothBorderRadius(
                      cornerRadius: 20,
                      cornerSmoothing: 1,
                    ),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: 20),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: _primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            HugeIcons.strokeRoundedFaceId,
                            color: _primaryColor,
                            size: 40,
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Face Not Registered',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Would you like to register your face now?',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context, false),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.black54,
                                side: BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 1.5,
                                ),
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: SmoothRectangleBorder(
                                  borderRadius: SmoothBorderRadius(
                                    cornerRadius: 12,
                                    cornerSmoothing: 0.8,
                                  ),
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.pop(context, true),
                              // icon: Icon(
                              //   HugeIcons.strokeRoundedFaceId,
                              //   size: 18,
                              // ),
                              label: Text(
                                'Register',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryColor,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: SmoothRectangleBorder(
                                  borderRadius: SmoothBorderRadius(
                                    cornerRadius: 12,
                                    cornerSmoothing: 0.8,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
          );

          if (shouldRegister == true) {
            // Navigate to face registration page
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => FaceRegistrationPage()),
            );
          }
          setState(() => _isLoading = false);
          return;
        }

        // Navigate to FaceRecognitionPage and wait for result
        final bool? recognitionSuccess = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder:
                (context) =>
                    FaceRecognitionPage(storedFaceEmbedding: faceEmbedding),
          ),
        );

        // Close loading dialog after returning from face capture
        Navigator.of(context).pop();

        // Check if face recognition was successful
        if (recognitionSuccess != true) {
          _showErrorDialog(context, 'Face recognition failed or was cancelled');
          setState(() => _isLoading = false);
          return;
        }

        // Show loading dialog before submitting attendance
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Center(
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: _primaryColor),
                    SizedBox(height: 16),
                    Text(
                      'Memproses...',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );

        try {
          // Prepare mode for attendance
          String mode =
              _selectedAttendanceTab == 'Masuk' ? 'checkin' : 'checkout';

          // Submit attendance
          Map<String, dynamic> attendanceResult =
              await AuthService.submitAttendance(scannedCode, mode);

          // Close loading dialog
          Navigator.of(context).pop();

          // Handle the attendance result
          if (attendanceResult['success'] == true) {
            // Update the check-in/check-out status
            await _loadCheckinStatus();
            await fetchRecentAttendance();

            // Show success message after state is updated
            if (mounted) {
              _showSuccessDialog(
                context,
                "${_selectedAttendanceTab} berhasil!",
              );
              // Force a rebuild to update the button state
              setState(() {});
            }
          } else {
            if (mounted) {
              _showErrorDialog(
                context,
                attendanceResult['message'] ?? 'Gagal melakukan absen',
              );
            }
          }
        } catch (e) {
          _showErrorDialog(
            context,
            'Error submitting attendance: ${e.toString()}',
          );
        }
      } catch (e) {
        print('Face recognition error: $e');
        Navigator.of(context).pop(); // Close loading dialog
        _showErrorDialog(
          context,
          'Error during face recognition: ${e.toString()}',
        );
      }
    } catch (e) {
      print('Attendance flow error: $e');
      // Close loading dialog if it's open
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      _showErrorDialog(
        context,
        'An unexpected error occurred: ${e.toString()}',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Removed duplicate _showErrorDialog and _showMessage methods

  void _showComingSoonTooltip() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 40),
              padding: EdgeInsets.all(20),
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: SmoothRectangleBorder(
                  borderRadius: SmoothBorderRadius(
                    cornerRadius: 16,
                    cornerSmoothing: 1,
                  ),
                ),
                shadows: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: ShapeDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      shape: SmoothRectangleBorder(
                        borderRadius: SmoothBorderRadius(
                          cornerRadius: 16,
                          cornerSmoothing: 1,
                        ),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        HugeIcons.strokeRoundedTime04,
                        color: Colors.orange,
                        size: 32,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Coming Soon',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Fitur ini akan segera tersedia untuk semua pengguna',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: SmoothRectangleBorder(
                          borderRadius: SmoothBorderRadius(
                            cornerRadius: 10,
                            cornerSmoothing: 0.8,
                          ),
                        ),
                      ),
                      child: Text(
                        'Mengerti',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                      ),
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _selectedIndex == 0 ? _buildAppBar() : null,
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Image.asset(
        'assets/logoappbar.png', // Make sure to add your logo to assets
        height: 18,
      ),
      actions: [
        IconButton(
          icon: Icon(
            HugeIcons.strokeRoundedNotification02,
            color: Colors.black, // Black icon
            size: 24,
          ),
          onPressed: () {
            // Handle notification tap
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return AttendanceHistoryPage();
      case 2:
        return TicketSupportPage();
      case 3:
        return ProfilePage();
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    return RefreshIndicator(
      color: _primaryColor,
      onRefresh: () async {
        await Future.wait([
          _loadUserProfile(),
          _loadCheckinStatus(),
          fetchRecentAttendance(),
        ]);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 20),
            _buildHRMShortcutsCard(),
            const SizedBox(height: 20),
            _buildRecentAttendanceCard(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      decoration: ShapeDecoration(
        color: _primaryColor,
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius(
            cornerRadius: 32,
            cornerSmoothing: 1,
          ),
        ),
      ),
      child: Stack(
        children: [
          // Decorative graphics in top right
          Positioned(
            top: 0,
            right: 0,
            child: Opacity(
              opacity: 0.1,
              child: Icon(
                HugeIcons.strokeRoundedCd,
                size: 120,
                color: Colors.white,
              ),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User info section
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userData['adminname'] ?? '',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _userData['username'] ?? '',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    // const SizedBox(height: 16),
                  ],
                ),
              ),

              // Attendance card
              _buildAttendanceCard(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius(
            cornerRadius: 24,
            cornerSmoothing: 1,
          ),
        ),
        shadows: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Tab selector
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
            child: Container(
              // padding: const EdgeInsets.all(4),
              decoration: ShapeDecoration(
                color: Colors.grey.shade100,
                shape: SmoothRectangleBorder(
                  borderRadius: SmoothBorderRadius(
                    cornerRadius: 12,
                    cornerSmoothing:
                        1, // Match the smoothing value used elsewhere
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildAttendanceTabButton(
                      'Masuk',
                      HugeIcons.strokeRoundedClock01,
                      _selectedAttendanceTab == 'Masuk',
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildAttendanceTabButton(
                      'Pulang',
                      HugeIcons.strokeRoundedClock01,
                      _selectedAttendanceTab == 'Pulang',
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              children: [
                Container(
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Text(
                        DateFormat('HH:mm', 'id_ID').format(DateTime.now()),
                        style: GoogleFonts.outfit(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat(
                          'EEEE, d MMMM yyyy',
                          'id_ID',
                        ).format(DateTime.now()),
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed:
                        ((_selectedAttendanceTab == 'Masuk' &&
                                    _checkedInToday) ||
                                (_selectedAttendanceTab == 'Pulang' &&
                                    _checkedOutToday) ||
                                _loadingCheckinStatus)
                            ? null
                            : _startAttendanceFlow,
                    icon: Icon(
                      _selectedAttendanceTab == 'Masuk'
                          ? HugeIcons.strokeRoundedFingerAccess
                          : HugeIcons.strokeRoundedLogout01,
                      size: 20,
                    ),
                    label: Text(
                      _selectedAttendanceTab == 'Masuk' &&
                              _checkedInToday &&
                              _jamIn != null
                          ? 'Sudah Absen: $_jamIn'
                          : _selectedAttendanceTab == 'Pulang' &&
                              _checkedOutToday &&
                              _jamOut != null
                          ? 'Sudah Absen: $_jamOut'
                          : _selectedAttendanceTab,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: SmoothRectangleBorder(
                        borderRadius: SmoothBorderRadius(
                          cornerRadius: 12,
                          cornerSmoothing: 0.8,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceTabButton(
    String label,
    IconData icon,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAttendanceTab = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: ShapeDecoration(
          color: isSelected ? _primaryColor : Colors.transparent,
          shape: SmoothRectangleBorder(
            borderRadius: SmoothBorderRadius(
              cornerRadius: 12,
              cornerSmoothing: 0.8,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHRMShortcutsCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Menu HRM',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: ShapeDecoration(
            color: Colors.white,
            shape: SmoothRectangleBorder(
              borderRadius: SmoothBorderRadius(
                cornerRadius: 20,
                cornerSmoothing: 1,
              ),
              side: BorderSide(color: Colors.grey.shade100, width: 2),
            ),
          ),
          child: Column(
            children: [
              // First row - 4 items
              Row(
                children: [
                  Expanded(
                    child: _buildShortcutItem(
                      'Izin',
                      HugeIcons.strokeRoundedCalendarRemove01,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildShortcutItem(
                      'Slip Gaji',
                      HugeIcons.strokeRoundedMoney01,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildShortcutItem(
                      'Kehadiran',
                      HugeIcons.strokeRoundedFile01,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildShortcutItem(
                      'Lembur',
                      HugeIcons.strokeRoundedClock03,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Second row - 4 items
              Row(
                children: [
                  Expanded(
                    child: _buildShortcutItem(
                      'Reimburse',
                      HugeIcons.strokeRoundedReceiptDollar,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildShortcutItem(
                      'Kinerja',
                      HugeIcons.strokeRoundedTarget01,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildShortcutItem(
                      'Absensi',
                      HugeIcons.strokeRoundedCheckmarkCircle01,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildShortcutItem(
                      'Karyawan',
                      HugeIcons.strokeRoundedUser,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShortcutItem(String title, IconData icon) {
    return GestureDetector(
      onTap: _showComingSoonTooltip,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(child: Icon(icon, color: _primaryColor, size: 24)),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
              height: 1.1, // Better line height for multi-line text
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  // Widget _buildAttendanceStatsCard() {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Padding(
  //         padding: const EdgeInsets.only(left: 4, bottom: 8),
  //         child: Text(
  //           'Statistik Kehadiran Bulan Ini',
  //           style: GoogleFonts.outfit(
  //             fontSize: 16,
  //             fontWeight: FontWeight.bold,
  //             color: Colors.black87,
  //           ),
  //         ),
  //       ),
  //       Container(
  //         padding: EdgeInsets.all(16),
  //         decoration: ShapeDecoration(
  //           color: Colors.white,
  //           shape: SmoothRectangleBorder(
  //             borderRadius: SmoothBorderRadius(
  //               cornerRadius: 20,
  //               cornerSmoothing: 1,
  //             ),
  //             side: BorderSide(color: Colors.grey.shade100, width: 2),
  //           ),
  //         ),
  //         child: Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceAround,
  //           children: [
  //             _buildStatItem(
  //               'Hadir',
  //               _attendanceStats['Hadir'] ?? 0,
  //               Colors.green,
  //             ),
  //             _buildStatItem(
  //               'Terlambat',
  //               _attendanceStats['Terlambat'] ?? 0,
  //               Colors.orange,
  //             ),
  //             _buildStatItem(
  //               'Izin',
  //               _attendanceStats['Izin'] ?? 0,
  //               Colors.blue,
  //             ),
  //             _buildStatItem(
  //               'Sakit',
  //               _attendanceStats['Sakit'] ?? 0,
  //               Colors.red,
  //             ),
  //           ],
  //         ),
  //       ),
  //     ],
  //   );
  // }

  // ignore: unused_element
  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: ShapeDecoration(
            color: color.withOpacity(0.1),
            shape: SmoothRectangleBorder(
              borderRadius: SmoothBorderRadius(
                cornerRadius: 12,
                cornerSmoothing: 1,
              ),
            ),
          ),
          child: Center(
            child: Text(
              count.toString(),
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildRecentAttendanceCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Riwayat Kehadiran Terbaru',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        Container(
          decoration: ShapeDecoration(
            color: Colors.white,
            shape: SmoothRectangleBorder(
              borderRadius: SmoothBorderRadius(
                cornerRadius: 20,
                cornerSmoothing: 1,
              ),
              side: BorderSide(color: Colors.grey.shade100, width: 2),
            ),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _recentAttendance.length,
            separatorBuilder:
                (context, index) => Divider(
                  height: 1,
                  color: Colors.grey.shade100,
                  thickness: 2,
                ),
            itemBuilder: (context, index) {
              final item = _recentAttendance[index];
              IconData statusIcon;
              Color statusColor;

              switch (item['status']) {
                case 'Hadir':
                  statusIcon = HugeIcons.strokeRoundedFingerPrintCheck;
                  statusColor = Colors.green;
                  break;
                case 'Terlambat':
                  statusIcon = HugeIcons.strokeRoundedTimeQuarter02;
                  statusColor = Colors.orange;
                  break;
                case 'Izin':
                  statusIcon = HugeIcons.strokeRoundedInformationCircle;
                  statusColor = Colors.blue;
                  break;
                case 'Sakit':
                  statusIcon = HugeIcons.strokeRoundedMedicalFile;
                  statusColor = Colors.red;
                  break;
                default:
                  statusIcon = HugeIcons.strokeRoundedHelpCircle;
                  statusColor = Colors.grey;
              }

              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: ShapeDecoration(
                    color: statusColor.withOpacity(0.1),
                    shape: SmoothRectangleBorder(
                      borderRadius: SmoothBorderRadius(
                        cornerRadius: 10,
                        cornerSmoothing: 1,
                      ),
                    ),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 20),
                ),
                title: Text(
                  DateFormat('EEEE, d MMMM', 'id_ID').format(item['date']),
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  'Masuk: ${item['clockIn']} · Keluar: ${item['clockOut']}',
                  style: GoogleFonts.outfit(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
                trailing: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: ShapeDecoration(
                    color: statusColor.withOpacity(0.1),
                    shape: SmoothRectangleBorder(
                      borderRadius: SmoothBorderRadius(
                        cornerRadius: 6,
                        cornerSmoothing: 1,
                      ),
                    ),
                  ),
                  child: Text(
                    item['status'],
                    style: GoogleFonts.outfit(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 10),
        TextButton(
          onPressed: () {
            setState(() {
              _selectedIndex = 1;
            });
          },
          style: TextButton.styleFrom(foregroundColor: _primaryColor),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Lihat Semua Riwayat',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
              ),
              SizedBox(width: 4),
              Icon(HugeIcons.strokeRoundedArrowRight02, size: 16),
            ],
          ),
        ),
      ],
    );
  }

  // ignore: unused_element
  Widget _buildComingSoonPage(String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(32),
            decoration: ShapeDecoration(
              color: _primaryColor.withOpacity(0.1),
              shape: SmoothRectangleBorder(
                borderRadius: SmoothBorderRadius(
                  cornerRadius: 30,
                  cornerSmoothing: 1,
                ),
              ),
            ),
            child: Icon(
              HugeIcons.strokeRoundedSettings04,
              size: 64,
              color: _primaryColor,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Halaman $title',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Fitur ini akan segera tersedia',
            style: GoogleFonts.outfit(fontSize: 16, color: Colors.black54),
          ),
          SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _selectedIndex = 0;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: SmoothRectangleBorder(
                borderRadius: SmoothBorderRadius(
                  cornerRadius: 12,
                  cornerSmoothing: 0.8,
                ),
              ),
            ),
            child: Text(
              'Kembali ke Beranda',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1.0),
        ),
      ),
      child: Theme(
        data: ThemeData(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            // Check if trying to access ticket page and user is not 'wahoy'
            if (index == 2 && _userData['username'] != 'wahoy') {
              _showComingSoonTooltip();
              return;
            }
            _animateIcon(index);
            setState(() {
              _selectedIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: _primaryColor,
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          unselectedLabelStyle: GoogleFonts.outfit(fontSize: 12),
          elevation: 0,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          enableFeedback: false,
          items: [
            _buildNavItem(0, HugeIcons.strokeRoundedHome01, 'Beranda'),
            _buildNavItem(1, HugeIcons.strokeRoundedCalendar03, 'Riwayat'),
            _buildNavItem(
              2,
              HugeIcons.strokeRoundedFile01,
              'Tiket',
              isEnabled: _userData['username'] == 'wahoy',
            ),
            _buildNavItem(3, HugeIcons.strokeRoundedUserSquare, 'Profil'),
          ],
        ),
      ),
    );
  }

  void _animateIcon(int index) {
    if (_iconKeys[index].currentState != null) {
      _iconKeys[index].currentState!.playAnimation();
    }
  }

  BottomNavigationBarItem _buildNavItem(
    int index,
    IconData icon,
    String label, {
    bool isEnabled = true,
  }) {
    return BottomNavigationBarItem(
      icon: GestureDetector(
        onTap:
            !isEnabled
                ? () {
                  // Show tooltip for disabled items
                  _showComingSoonTooltip();
                }
                : null,
        child: ScaleIcon(
          key: _iconKeys[index],
          icon: icon,
          color:
              !isEnabled
                  ? Colors.grey.shade400
                  : (_selectedIndex == index ? _primaryColor : Colors.grey),
        ),
      ),
      label: label,
    );
  }
}

class QRScanDialog extends StatelessWidget {
  final MobileScannerController controller = MobileScannerController();

  @override
  Widget build(BuildContext context) {
    final primaryColor = Color(0xFF143CFF);

    return Dialog(
      shape: SmoothRectangleBorder(
        borderRadius: SmoothBorderRadius(cornerRadius: 20, cornerSmoothing: 1),
      ),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Scan QR Code",
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    controller.stop();
                    Navigator.of(context).pop();
                  },
                  icon: Icon(
                    HugeIcons.strokeRoundedCancelCircle,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              "Arahkan kamera ke QR Code untuk absensi",
              style: GoogleFonts.outfit(fontSize: 14, color: Colors.black54),
            ),
            SizedBox(height: 16),
            Container(
              width: 280,
              height: 280,
              decoration: ShapeDecoration(
                shape: SmoothRectangleBorder(
                  borderRadius: SmoothBorderRadius(
                    cornerRadius: 16,
                    cornerSmoothing: 1,
                  ),
                ),
              ),
              child: ClipSmoothRect(
                radius: SmoothBorderRadius(
                  cornerRadius: 16,
                  cornerSmoothing: 1,
                ),
                child: MobileScanner(
                  controller: controller,
                  onDetect: (capture) {
                    final barcode = capture.barcodes.first;
                    final String? code = barcode.rawValue;
                    if (code != null) {
                      controller.stop();
                      Navigator.of(context).pop(code);
                    }
                  },
                ),
              ),
            ),
            SizedBox(height: 20),
            Container(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: Icon(HugeIcons.strokeRoundedRefresh, size: 18),
                label: Text(
                  "Coba Lagi",
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
                ),
                onPressed: () {
                  // Reset scanner
                  controller.start();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  side: BorderSide(color: primaryColor, width: 1.5),
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: SmoothRectangleBorder(
                    borderRadius: SmoothBorderRadius(
                      cornerRadius: 12,
                      cornerSmoothing: 0.8,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 12),
            Container(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  controller.stop();
                  Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(foregroundColor: Colors.black54),
                child: Text(
                  "Batal",
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ScaleIcon extends StatefulWidget {
  final IconData icon;
  final Color color;

  const ScaleIcon({Key? key, required this.icon, required this.color})
    : super(key: key);

  @override
  _ScaleIconState createState() => _ScaleIconState();
}

class _ScaleIconState extends State<ScaleIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );

    _animation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.8), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: 0.8, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  void playAnimation() {
    _controller.forward(from: 0.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: Icon(widget.icon, color: widget.color),
        );
      },
    );
  }
}
