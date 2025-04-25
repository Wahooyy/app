import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // Add this import
import '../services/auth_service.dart';
import 'profile.dart';


class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final LocalAuthentication auth = LocalAuthentication();
  int _selectedIndex = 0;
  final String _username = "Maman Racing"; // Replace with actual user data
  final String _position = "Staff IT Pindahan";
  final Color _primaryColor = Color(0xFF6200EE);
  
  @override
  void initState() {
    super.initState();
    // Initialize the date formatting for Indonesian locale
    initializeDateFormatting('id_ID', null);
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

    bool success = await AuthService.submitAttendance(scannedCode);
    if (success) {
      _showMessage("Absensi berhasil!");
    } else {
      _showMessage("Gagal menyimpan absensi.");
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
      floatingActionButton: _buildAttendanceButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Text(
          //   'Dashboard Kehadiran',
          //   style: GoogleFonts.outfit(
          //     color: Colors.black87,
          //     fontWeight: FontWeight.bold,
          //     fontSize: 18,
          //   ),
          // ),
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
        return Container(); // This is where the attendance button sits
      case 3:
        return _buildComingSoonPage("Riwayat Kehadiran");
      case 4:
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
          _buildAttendanceStatsCard(),
          SizedBox(height: 20),
          _buildRecentAttendanceCard(),
          SizedBox(height: 70), // Extra space for FAB
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
        // shadows: [
        //   BoxShadow(
        //     color: Colors.black.withOpacity(0.05),
        //     blurRadius: 10,
        //     offset: Offset(0, 4),
        //   ),
        // ],
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
                _username.substring(0, 1),
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
                  _username,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  _position,
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
            // shadows: [
            //   BoxShadow(
            //     color: Colors.black.withOpacity(0.05),
            //     blurRadius: 10,
            //     offset: Offset(0, 4),
            //   ),
            // ],
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
            // shadows: [
            //   BoxShadow(
            //     color: Colors.black.withOpacity(0.05),
            //     blurRadius: 10,
            //     offset: Offset(0, 4),
            //   ),
            // ],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _recentAttendance.length,
            separatorBuilder: (context, index) => Divider(height: 1),
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
              _selectedIndex = 3;
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

  Widget _buildAttendanceButton() {
    return Container(
      height: 64,
      width: 64,
      margin: EdgeInsets.only(top: 30),
      child: FloatingActionButton(
        onPressed: _startAttendanceFlow,
        backgroundColor: _primaryColor,
        child: Icon(
          HugeIcons.strokeRoundedFingerprintScan,
          size: 24,
          color: Colors.white,
        ),
        elevation: 4,
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius(
            cornerRadius: 50,
            cornerSmoothing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
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
        items: [
          BottomNavigationBarItem(
            icon: Icon(HugeIcons.strokeRoundedHome01),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(HugeIcons.strokeRoundedCalendarRemove01),
            label: 'Izin',
          ),
          BottomNavigationBarItem(
            icon: Icon(null),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(HugeIcons.strokeRoundedFile01),
            label: 'Riwayat',
          ),
          BottomNavigationBarItem(
            icon: Icon(HugeIcons.strokeRoundedUser),
            label: 'Profil',
          ),
        ],
      ),
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