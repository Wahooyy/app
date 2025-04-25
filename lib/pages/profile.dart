import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
// ignore: unused_import
import '../services/auth_service.dart';
import 'dart:io';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final Color _primaryColor = Color(0xFF6200EE);
  final ImagePicker _picker = ImagePicker();
  File? _profileImage;
  bool _isEditing = false;
  bool _isLoading = false;

  // Sample user data - would come from your AuthService in a real app
  Map<String, dynamic> _userData = {
    'name': 'Maman Racing',
    'email': 'mamanracing@kahaptex.co.id',
    'phone': '+62 812 3456 7890',
    'position': 'Staff IT Pindahan',
    'department': 'Informasi Teknologi',
    'employeeId': 'MMK-2023-0042',
    'joinDate': '15 Januari 2023',
    'address': 'Jl. Raya Kedep',
  };

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = _userData['name'] ?? '';
    _emailController.text = _userData['email'] ?? '';
    _phoneController.text = _userData['phone'] ?? '';
    _addressController.text = _userData['address'] ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
    }
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        // Reset controllers to original values if canceling edit
        _nameController.text = _userData['name'] ?? '';
        _emailController.text = _userData['email'] ?? '';
        _phoneController.text = _userData['phone'] ?? '';
        _addressController.text = _userData['address'] ?? '';
      }
    });
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate API call with delay
      await Future.delayed(Duration(seconds: 1));
      
      // Update local data
      setState(() {
        _userData['name'] = _nameController.text;
        _userData['email'] = _emailController.text;
        _userData['phone'] = _phoneController.text;
        _userData['address'] = _addressController.text;
        _isEditing = false;
        _isLoading = false;
      });
      
      _showMessage('Profil berhasil diperbarui!');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showMessage('Gagal memperbarui profil. Silakan coba lagi.');
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
        title: Text(
          'Profil Saya',
          style: GoogleFonts.outfit(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: Icon(HugeIcons.strokeRoundedArrowLeft01, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          _isEditing
              ? Row(
                  children: [
                    TextButton(
                      onPressed: _toggleEdit,
                      child: Text(
                        'Batal',
                        style: GoogleFonts.outfit(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _isLoading ? null : _saveChanges,
                      child: _isLoading
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _primaryColor,
                              ),
                            )
                          : Text(
                              'Simpan',
                              style: GoogleFonts.outfit(
                                color: _primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                )
              : IconButton(
                  icon: Icon(
                    HugeIcons.strokeRoundedEdit01,
                    color: Colors.black87,
                  ),
                  onPressed: _toggleEdit,
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProfileHeader(),
            SizedBox(height: 24),
            _isEditing ? _buildEditableForm() : _buildProfileDetails(),
            SizedBox(height: 24),
            if (!_isEditing) _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
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
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 100,
                height: 100,
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
                          _userData['name']?.substring(0, 1) ?? 'A',
                          style: GoogleFonts.outfit(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: _primaryColor,
                          ),
                        ),
                      )
                    : null,
              ),
              if (_isEditing)
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: ShapeDecoration(
                      color: _primaryColor,
                      shape: SmoothRectangleBorder(
                        borderRadius: SmoothBorderRadius(
                          cornerRadius: 12,
                          cornerSmoothing: 1,
                        ),
                      ),
                    ),
                    child: Icon(
                      HugeIcons.strokeRoundedCamera01,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            _userData['name'] ?? 'User',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 4),
          Text(
            _userData['position'] ?? 'Position',
            style: GoogleFonts.outfit(
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
          SizedBox(height: 4),
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

  Widget _buildProfileDetails() {
    return Column(
      children: [
        _buildInfoSection(
          'Informasi Pribadi',
          [
            _buildInfoItem(
              HugeIcons.strokeRoundedMail02,
              'Email',
              _userData['email'] ?? '-',
            ),
            _buildInfoItem(
              HugeIcons.strokeRoundedSmartPhone02,
              'Nomor Telepon',
              _userData['phone'] ?? '-',
            ),
            _buildInfoItem(
              HugeIcons.strokeRoundedLocation05,
              'Alamat',
              _userData['address'] ?? '-',
            ),
          ],
        ),
        SizedBox(height: 20),
        _buildInfoSection(
          'Informasi Pekerjaan',
          [
            _buildInfoItem(
              HugeIcons.strokeRoundedBuilding02,
              'Departemen',
              _userData['department'] ?? '-',
            ),
            _buildInfoItem(
              HugeIcons.strokeRoundedUserAccount,
              'ID Karyawan',
              _userData['employeeId'] ?? '-',
            ),
            _buildInfoItem(
              HugeIcons.strokeRoundedCalendar01,
              'Tanggal Bergabung',
              _userData['joinDate'] ?? '-',
            ),
          ],
        ),
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
        // shadows: [
        //   BoxShadow(
        //     color: Colors.black.withOpacity(0.05),
        //     blurRadius: 10,
        //     offset: Offset(0, 4),
        //   ),
        // ],
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
          Divider(height: 1),
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

  Widget _buildEditableForm() {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Edit Profil',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16),
          _buildTextField(
            controller: _nameController,
            label: 'Nama Lengkap',
            icon: HugeIcons.strokeRoundedUser03,
          ),
          SizedBox(height: 16),
          _buildTextField(
            controller: _emailController,
            label: 'Email',
            icon: HugeIcons.strokeRoundedMail01,
            keyboardType: TextInputType.emailAddress,
          ),
          SizedBox(height: 16),
          _buildTextField(
            controller: _phoneController,
            label: 'Nomor Telepon',
            icon: HugeIcons.strokeRoundedSmartPhone02,
            keyboardType: TextInputType.phone,
          ),
          SizedBox(height: 16),
          _buildTextField(
            controller: _addressController,
            label: 'Alamat',
            icon: HugeIcons.strokeRoundedLocation05,
            maxLines: 3,
          ),
          SizedBox(height: 8),
          Text(
            'Informasi pekerjaan hanya dapat diubah oleh admin',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: Colors.black54,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      style: GoogleFonts.outfit(),
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.outfit(
          color: Colors.grey.shade700,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Icon(icon),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
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