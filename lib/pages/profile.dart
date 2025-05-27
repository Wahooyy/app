import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:hugeicons/hugeicons.dart';
// import 'package:image_picker/image_picker.dart';
// ignore: unused_import
import '../services/auth_service.dart';
import 'dart:io';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final Color _primaryColor = Color(0xFF6200EE);
  // final ImagePicker _picker = ImagePicker();
  File? _profileImage;
  bool _isLoadingProfile = true;

  // Initialize with empty values
  Map<String, dynamic> _userData = {
    'adminname': '',
    'username': '',
    'nip': '',
    'email': '',
    'address': '',
  };

  @override
  void initState() {
    super.initState();
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

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius(
            cornerRadius: 20,
            cornerSmoothing: 1,
          ),
        ),
        title: Text(
          'Keluar',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar?',
          style: GoogleFonts.outfit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: GoogleFonts.outfit(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Handle logout logic
              // AuthService.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              shape: SmoothRectangleBorder(
                borderRadius: SmoothBorderRadius(
                  cornerRadius: 10,
                  cornerSmoothing: 0.8,
                ),
              ),
            ),
            child: Text(
              'Keluar',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w500,
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Profil Saya',
          style: GoogleFonts.outfit(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        // leading: IconButton(
        //   icon: Icon(HugeIcons.strokeRoundedArrowLeft01, color: Colors.black87),
        //   onPressed: () => Navigator.pop(context),
        // ),
      ),
      body: _isLoadingProfile 
        ? Center(
            child: CircularProgressIndicator(color: _primaryColor),
          )
        : SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                _buildProfileHeader(),
                SizedBox(height: 24),
                _buildProfileDetails(),
                SizedBox(height: 24),
                _buildActionButtons(),
              ],
            ),
          ),
    );
  }

  Widget _buildProfileHeader() {
    return Stack(
      children: [
        // Gradient background behind the card
        Container(
          height: 200,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _primaryColor.withOpacity(0.12),
                Colors.white,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: Container(
            margin: EdgeInsets.only(top: 32),
            padding: EdgeInsets.all(20),
            decoration: ShapeDecoration(
              color: Colors.white,
              shadows: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
              shape: SmoothRectangleBorder(
                borderRadius: SmoothBorderRadius(
                  cornerRadius: 24,
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
                Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _primaryColor.withOpacity(0.18),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                        border: Border.all(
                          color: _primaryColor.withOpacity(0.25),
                          width: 3,
                        ),
                      ),
                      child: Container(
                        decoration: ShapeDecoration(
                          color: _primaryColor.withOpacity(0.1),
                          shape: SmoothRectangleBorder(
                            borderRadius: SmoothBorderRadius(
                              cornerRadius: 50,
                              cornerSmoothing: 1,
                            ),
                          ),
                          image: _profileImage != null
                              ? DecorationImage(
                                  image: FileImage(_profileImage!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _profileImage == null
                            ? Center(
                                child: Text(
                                  (_userData['adminname']?.isNotEmpty == true)
                                      ? _userData['adminname']!.substring(0, 1)
                                      : 'A',
                                  style: GoogleFonts.outfit(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: _primaryColor,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                    // Edit icon overlay (future use)
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          HugeIcons.strokeRoundedEdit02,
                          color: _primaryColor,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 18),
                Text(
                  _userData['adminname'] ?? 'Nama',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _userData['username'] ?? 'Username',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    color: Colors.black54,
                  ),
                ),
                SizedBox(height: 10),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: ShapeDecoration(
                    color: Colors.green.withOpacity(0.12),
                    shape: SmoothRectangleBorder(
                      borderRadius: SmoothBorderRadius(
                        cornerRadius: 10,
                        cornerSmoothing: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, color: Colors.green, size: 10),
                      SizedBox(width: 6),
                      Text(
                        'Aktif',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileDetails() {
    return Column(
      children: [
        _buildInfoSection(
          'Informasi',
          [
            _buildInfoItem(
              HugeIcons.strokeRoundedMail02,
              'Email',
              _userData['email'] ?? '-',
            ),
            _buildInfoItem(
              HugeIcons.strokeRoundedUserAccount,
              'NIP',
              _userData['nip'] ?? '-',
            ),
            _buildInfoItem(
              HugeIcons.strokeRoundedLocation05,
              'Alamat',
              _userData['location'] ?? '-',
            ),
          ],
        ),
        SizedBox(height: 20),
      ],
    );
  }

  Widget _buildInfoSection(String title, List<Widget> items) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Divider(
            height: 1,
            thickness: 2,
            color: Colors.grey.shade100,
            indent: 16,
            endIndent: 16,
          ),
          ...items,
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: ShapeDecoration(
              color: _primaryColor.withOpacity(0.1),
              shape: SmoothRectangleBorder(
                borderRadius: SmoothBorderRadius(
                  cornerRadius: 10,
                  cornerSmoothing: 1,
                ),
              ),
            ),
            child: Icon(icon, color: _primaryColor, size: 20),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        _buildActionButton(
          icon: HugeIcons.strokeRoundedSquareLock02,
          label: 'Ubah Kata Sandi',
          color: Colors.blue,
          onTap: () => _showMessage('Fitur segera hadir!'),
        ),
        SizedBox(height: 12),
        _buildActionButton(
          icon: HugeIcons.strokeRoundedFingerAccess,
          label: 'Kelola Login Fingerprint',
          color: Colors.teal,
          onTap: () => _showMessage('Fitur segera hadir!'),
        ),
        SizedBox(height: 12),
        _buildActionButton(
          icon: HugeIcons.strokeRoundedNotification03,
          label: 'Pengaturan Notifikasi',
          color: Colors.amber[700]!,
          onTap: () => _showMessage('Fitur segera hadir!'),
        ),
        SizedBox(height: 12),
        _buildActionButton(
          icon: HugeIcons.strokeRoundedLogout03,
          label: 'Keluar',
          color: Colors.red,
          onTap: _logout,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
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
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: ShapeDecoration(
                color: color.withOpacity(0.1),
                shape: SmoothRectangleBorder(
                  borderRadius: SmoothBorderRadius(
                    cornerRadius: 10,
                    cornerSmoothing: 1,
                  ),
                ),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            Icon(
              HugeIcons.strokeRoundedArrowRight01,
              color: Colors.black54,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}