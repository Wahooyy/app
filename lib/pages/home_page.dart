import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../services/auth_service.dart';
import 'profile.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final LocalAuthentication auth = LocalAuthentication();
  int _selectedIndex = 0;
  final String _username = "Maman Racing";
  final String _position = "Staff IT Pindahan";
  final Color _primaryColor = Color(0xFF6200EE);
  final List<GlobalKey<_ScaleIconState>> _iconKeys = List.generate(4, (_) => GlobalKey<_ScaleIconState>());
  bool _isLoadingProfile = true;

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
  String _selectedAttendanceTab = 'Check In';
  
  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);
    _loadUserProfile();

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

  // Sample data for recent attendance
  final List<Map<String, dynamic>> _recentAttendance = [
    {
      'date': DateTime.now().subtract(Duration(days: 0)),
      'clockIn': '08:05',
      'clockOut': '17:30',
      'status': 'Hadir',
    },
    {
      'date': DateTime.now().subtract(Duration(days: 1)),
      'clockIn': '08:00',
      'clockOut': '17:15',
      'status': 'Hadir',
    },
    {
      'date': DateTime.now().subtract(Duration(days: 2)),
      'clockIn': '08:30',
      'clockOut': '17:45',
      'status': 'Terlambat',
    },
    {
      'date': DateTime.now().subtract(Duration(days: 3)),
      'clockIn': '--:--',
      'clockOut': '--:--',
      'status': 'Izin',
    },
  ];

  // Sample data for attendance statistics
  final Map<String, int> _attendanceStats = {
    'Hadir': 18,
    'Terlambat': 2,
    'Izin': 1,
    'Sakit': 1,
  };

  // Add this function to your _HomePageState class
  void _showLoadingDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
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
          CircularProgressIndicator(
            color: _primaryColor,
            strokeWidth: 3,
          ),
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
    builder: (context) => AlertDialog(
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


  Future<void> _startAttendanceFlow() async {
    String? scannedCode = await showDialog(
      context: context,
      builder: (_) => QRScanDialog(),
    );

    if (scannedCode == null) return;

    bool authenticated = await auth.authenticate(
      localizedReason: 'Verifikasi fingerprint untuk absensi',
      options: const AuthenticationOptions(biometricOnly: true),
    );

    if (!authenticated) {
      _showMessage("Verifikasi fingerprint gagal.");
      return;
    }

    _showLoadingDialog(context); // 1. tampilkan dialog loading

    bool success = await AuthService.submitAttendance(scannedCode); // 2. tunggu API

    Navigator.of(context).pop(); // 3. tutup loading dialog

    if (success) {
      _showSuccessDialog(context, "${_selectedAttendanceTab} berhasil!"); // 4. tampilkan dialog sukses
    } else {
      _showMessage("Gagal menyimpan absensi."); // 4. atau error message
    }

  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
        ),
        backgroundColor: _primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius(
            cornerRadius: 10,
            cornerSmoothing: 1,
          ),
        ),
        margin: EdgeInsets.all(10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now()),
            style: GoogleFonts.outfit(
              color: Colors.black54,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: EdgeInsets.all(8),
            decoration: ShapeDecoration(
              color: _primaryColor.withOpacity(0.1),
              shape: SmoothRectangleBorder(
                borderRadius: SmoothBorderRadius(
                  cornerRadius: 10,
                  cornerSmoothing: 1,
                ),
              ),
            ),
            child: Icon(HugeIcons.strokeRoundedNotification02, color: _primaryColor, size: 20),
          ),
          onPressed: () {},
        ),
        SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return _buildComingSoonPage("Izin");
      case 2:
        return _buildComingSoonPage("Riwayat Kehadiran");
      case 3:
        return ProfilePage();
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeCard(),
          SizedBox(height: 20),
          _buildAttendanceCard(), // New attendance card with check-in/check-out tabs
          SizedBox(height: 20),
          _buildAttendanceStatsCard(),
          SizedBox(height: 20),
          _buildRecentAttendanceCard(),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius(
            cornerRadius: 20,
            cornerSmoothing: 1,
          ),
          side: BorderSide(
            color: Colors.grey.shade100,
            width: 2,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: ShapeDecoration(
              color: _primaryColor.withOpacity(0.1),
              shape: SmoothRectangleBorder(
                borderRadius: SmoothBorderRadius(
                  cornerRadius: 16,
                  cornerSmoothing: 1,
                ),
              ),
            ),
            child: Center(
              child: Text(
                _userData['adminname'].substring(0, 1),
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selamat Datang,',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _userData['adminname'],
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  _userData['username'],
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: ShapeDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: SmoothRectangleBorder(
                borderRadius: SmoothBorderRadius(
                  cornerRadius: 8,
                  cornerSmoothing: 1,
                ),
              ),
            ),
            child: Text(
              'Aktif',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // New widget for attendance check-in/check-out
  Widget _buildAttendanceCard() {
    return Container(
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius(
            cornerRadius: 20,
            cornerSmoothing: 1,
          ),
          side: BorderSide(
            color: Colors.grey.shade100,
            width: 2,
          ),
        ),
      ),
      child: Column(
        children: [
          // Tab selector
          Container(
            padding: EdgeInsets.all(6),
            decoration: ShapeDecoration(
              color: Colors.grey.shade50,
              shape: SmoothRectangleBorder(
                borderRadius: SmoothBorderRadius(
                  cornerRadius: 16,
                  cornerSmoothing: 1,
                ),
              ),
            ),
            margin: EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: _buildAttendanceTabButton(
                    'Masuk',
                    HugeIcons.strokeRoundedClock01,
                    _selectedAttendanceTab == 'Masuk',
                  ),
                ),
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

          // Content
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 20),
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
                      SizedBox(height: 4),
                      Text(
                        DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now()),
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _startAttendanceFlow,
                    icon: Icon(
                      _selectedAttendanceTab == 'Masuk'
                          ? HugeIcons.strokeRoundedFingerprintScan
                          : HugeIcons.strokeRoundedLogout01,
                      size: 20,
                    ),
                    label: Text(
                      _selectedAttendanceTab,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
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

  Widget _buildAttendanceTabButton(String label, IconData icon, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAttendanceTab = label;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: ShapeDecoration(
          color: isSelected ? _primaryColor : Colors.transparent,
          shape: SmoothRectangleBorder(
            borderRadius: SmoothBorderRadius(
              cornerRadius: 12,
              cornerSmoothing: 1,
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
            SizedBox(width: 8),
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

  Widget _buildAttendanceStatsCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Statistik Kehadiran Bulan Ini',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.all(16),
          decoration: ShapeDecoration(
            color: Colors.white,
            shape: SmoothRectangleBorder(
              borderRadius: SmoothBorderRadius(
                cornerRadius: 20,
                cornerSmoothing: 1,
              ),
              side: BorderSide(
                color: Colors.grey.shade100,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Hadir', _attendanceStats['Hadir'] ?? 0, Colors.green),
              _buildStatItem('Terlambat', _attendanceStats['Terlambat'] ?? 0, Colors.orange),
              _buildStatItem('Izin', _attendanceStats['Izin'] ?? 0, Colors.blue),
              _buildStatItem('Sakit', _attendanceStats['Sakit'] ?? 0, Colors.red),
            ],
          ),
        ),
      ],
    );
  }

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
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: Colors.black54,
          ),
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
              side: BorderSide(
                color: Colors.grey.shade100,
                width: 2,
              ),
            ),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _recentAttendance.length,
            separatorBuilder: (context, index) => Divider(
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
              _selectedIndex = 2;
            });
          },
          style: TextButton.styleFrom(
            foregroundColor: _primaryColor,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Lihat Semua Riwayat',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 4),
              Icon(HugeIcons.strokeRoundedArrowRight02, size: 16),
            ],
          ),
        ),
      ],
    );
  }

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
            style: GoogleFonts.outfit(
              fontSize: 16,
              color: Colors.black54,
            ),
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
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
              ),
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
          top: BorderSide(
            color: Colors.grey.withOpacity(0.2),
            width: 1.0,
          ),
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
          unselectedLabelStyle: GoogleFonts.outfit(
            fontSize: 12,
          ),
          elevation: 0,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          enableFeedback: false,
          items: [
            _buildNavItem(0, HugeIcons.strokeRoundedHome01, 'Beranda'),
            _buildNavItem(1, HugeIcons.strokeRoundedCalendarRemove01, 'Izin'),
            _buildNavItem(2, HugeIcons.strokeRoundedFile01, 'Riwayat'),
            _buildNavItem(3, HugeIcons.strokeRoundedUser, 'Profil'),
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

  BottomNavigationBarItem _buildNavItem(int index, IconData icon, String label) {
    return BottomNavigationBarItem(
      icon: ScaleIcon(
        key: _iconKeys[index],
        icon: icon,
        color: _selectedIndex == index ? _primaryColor : Colors.grey,
      ),
      label: label,
    );
  }
}

class QRScanDialog extends StatelessWidget {
  final MobileScannerController controller = MobileScannerController();

  @override
  Widget build(BuildContext context) {
    final primaryColor = Color(0xFF6200EE);
    
    return Dialog(
      shape: SmoothRectangleBorder(
        borderRadius: SmoothBorderRadius(
          cornerRadius: 20,
          cornerSmoothing: 1,
        ),
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
                  icon: Icon(HugeIcons.strokeRoundedCancelCircle, color: Colors.black54),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              "Arahkan kamera ke QR Code untuk absensi",
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: Colors.black54,
              ),
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
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w500,
                  ),
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
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black54,
                ),
                child: Text(
                  "Batal",
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w500,
                  ),
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

  const ScaleIcon({
    Key? key,
    required this.icon,
    required this.color,
  }) : super(key: key);

  @override
  _ScaleIconState createState() => _ScaleIconState();
}

class _ScaleIconState extends State<ScaleIcon> with SingleTickerProviderStateMixin {
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
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.8),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.8, end: 1.0),
        weight: 1,
      ),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
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
          child: Icon(
            widget.icon,
            color: widget.color,
          ),
        );
      },
    );
  }
}