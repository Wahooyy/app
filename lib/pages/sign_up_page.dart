import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../services/auth_service.dart';
import 'package:uuid/uuid.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:hugeicons/hugeicons.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = LocalAuthentication();
  final _uuid = Uuid();

  bool _loading = false;
  String? _error;
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.4, 1.0, curve: Curves.easeInOut),
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Function to get real device ID
  Future<String> _getDeviceId() async {
    String deviceId = '';
    final _deviceInfo = DeviceInfoPlugin();

    if (Theme.of(context).platform == TargetPlatform.iOS) {
      IosDeviceInfo iosInfo = await _deviceInfo.iosInfo;
      deviceId = iosInfo.identifierForVendor ?? 'unknown';
    } else {
      AndroidDeviceInfo androidInfo = await _deviceInfo.androidInfo;
      deviceId = androidInfo.id ?? 'unknown'; // Using androidInfo.id for Android
    }
    return deviceId;
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
        ),
        backgroundColor: isError ? Colors.red.shade700 : Color(0xFF6200EE),
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

  Future<void> _signUp() async {
    // Validate inputs
    if (_nameController.text.isEmpty || 
        _usernameController.text.isEmpty || 
        _passwordController.text.isEmpty) {
      _showMessage('Please fill all fields', isError: true);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Ask for fingerprint
      bool authenticated = await _auth.authenticate(
        localizedReason: 'Register your fingerprint for secure login',
        options: const AuthenticationOptions(biometricOnly: true),
      );

      if (!authenticated) {
        setState(() {
          _loading = false;
          _error = 'Fingerprint registration failed';
        });
        _showMessage('Fingerprint registration failed', isError: true);
        return;
      }

      // Generate fingerprint token (This is a placeholder, make sure your backend generates the real one)
      String fingerprintToken = _uuid.v4();  // or use a different method to generate a unique token

      // Get real device ID
      String deviceId = await _getDeviceId();

      // Register with backend (sending name, username, password, fingerprint token, device ID)
      bool success = await AuthService.registerWithFingerprint(
        _nameController.text,
        _usernameController.text,
        _passwordController.text,
        fingerprintToken, // Send generated fingerprint token
        deviceId, // Send the real device ID
      );

      if (success) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        setState(() {
          _loading = false;
          _error = 'Registration failed';
        });
        _showMessage('Registration failed. Please try again.', isError: true);
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'An error occurred';
      });
      _showMessage('An error occurred. Please try again.', isError: true);
    }
  }

  // Custom input decoration with FigmaSquircle
  InputDecoration _getInputDecoration({
    required String label,
    required String hint,
    required Widget prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      labelStyle: GoogleFonts.outfit(
        color: Colors.grey.shade700,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: GoogleFonts.outfit(
        color: Colors.grey.shade400,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Color(0xFF6200EE), width: 2),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: EdgeInsets.symmetric(vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Color(0xFF6200EE); // Deep purple
    
    return Scaffold(
      backgroundColor: Colors.white,
      // appBar: AppBar(
      //   title: Text(
      //     'Create Account',
      //     style: GoogleFonts.outfit(
      //       fontWeight: FontWeight.w600,
      //     ),
      //   ),
      //   backgroundColor: Colors.white,
      //   foregroundColor: Colors.black87,
      //   elevation: 0,
      //   centerTitle: true,
      //   leading: IconButton(
      //     icon: Icon(HugeIcons.strokeRoundedArrowLeft02),
      //     onPressed: () => Navigator.of(context).pop(),
      //   ),
      // ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header section
                  Center(
                    child: Container(
                      padding: EdgeInsets.all(15),
                      decoration: ShapeDecoration(
                        color: primaryColor.withOpacity(0.1),
                        shape: SmoothRectangleBorder(
                          borderRadius: SmoothBorderRadius(
                            cornerRadius: 25,
                            cornerSmoothing: 1,
                          ),
                        ),
                      ),
                      child: Icon(HugeIcons.strokeRoundedUserAdd01),
                    ),
                  ),
                  SizedBox(height: 30),
                  
                  // Title
                  Center(
                    child: Text(
                      'Daftar',
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Buat akun baru',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  SizedBox(height: 35),
                  
                  // Form fields
                  Text(
                    'Informasi akun',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 15),
                  
                  // Name Field
                  TextFormField(
                    controller: _nameController,
                    style: GoogleFonts.outfit(),
                    decoration: _getInputDecoration(
                      label: 'Nama Lengkap',
                      hint: 'Masukkan nama lengkap',
                      prefixIcon: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(HugeIcons.strokeRoundedUser03),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  // Username Field
                  TextFormField(
                    controller: _usernameController,
                    style: GoogleFonts.outfit(),
                    decoration: _getInputDecoration(
                      label: 'Username',
                      hint: 'Pilih username',
                      prefixIcon: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(HugeIcons.strokeRoundedAt),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: GoogleFonts.outfit(),
                    decoration: _getInputDecoration(
                      label: 'Kata Sandi',
                      hint: 'Buat kata sandi',
                      prefixIcon: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(HugeIcons.strokeRoundedSquareLock02),
                      ),
                      suffixIcon: IconButton(
                        icon: _obscurePassword 
                            ? Icon(HugeIcons.strokeRoundedView)
                            : Icon(HugeIcons.strokeRoundedViewOffSlash),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  
                  // Password requirements
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Text(
                      'Kata sandi harus terdiri dari minimal 8 karakter.',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  
                  // Error message if any
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        decoration: ShapeDecoration(
                          color: Colors.red.shade50,
                          shape: SmoothRectangleBorder(
                            borderRadius: SmoothBorderRadius(
                              cornerRadius: 10,
                              cornerSmoothing: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style: GoogleFonts.outfit(
                                  color: Colors.red.shade700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  SizedBox(height: 30),
                  
                  // Signup Button
                  Container(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      icon: Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Icon(HugeIcons.strokeRoundedFingerAccess),
                      ),
                      label: Text(
                        'Daftar',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: _loading ? null : _signUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: SmoothRectangleBorder(
                          borderRadius: SmoothBorderRadius(
                            cornerRadius: 16,
                            cornerSmoothing: 0.8,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Loading indicator
                  if (_loading)
                    Center(
                      child: CircularProgressIndicator(
                        color: primaryColor,
                      ),
                    ),
                  
                  SizedBox(height: 30),
                  
                  // Login Link
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Sudah punya akun?",
                          style: GoogleFonts.outfit(
                            color: Colors.black54,
                            fontSize: 14,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, '/login');
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: primaryColor,
                            padding: EdgeInsets.only(left: 5),
                            minimumSize: Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Masuk',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
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
    );
  }
}