import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import '../services/auth_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:hugeicons/hugeicons.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = LocalAuthentication();
  bool _isLoading = false;
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
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
        ),
        backgroundColor: Color(0xFF6200EE),
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

  Future<void> _handleLogin() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      _showMessage('Please enter both username and password');
      return;
    }

    setState(() => _isLoading = true);
    final username = _usernameController.text;
    final password = _passwordController.text;

    try {
      final success = await AuthService.login(username, password);
      if (success) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        _showMessage('Login failed. Please check your credentials.');
      }
    } catch (e) {
      _showMessage('An error occurred. Please try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleFingerprintLogin() async {
    setState(() => _isLoading = true);
    
    try {
      final authenticated = await _auth.authenticate(
        localizedReason: 'Authenticate to continue',
        options: const AuthenticationOptions(biometricOnly: true),
      );

      if (!authenticated) {
        _showMessage("Authentication failed. Please try again.");
        setState(() => _isLoading = false);
        return;
      }

      // Get device info and a valid device ID
      final deviceInfo = DeviceInfoPlugin();
      String deviceId = '';

      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id ?? '';
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? '';
      } else {
        _showMessage('Unsupported device');
        setState(() => _isLoading = false);
        return;
      }

      // Get fingerprint token based on device ID from database
      final token = await AuthService.getFingerprintToken(deviceId);

      if (token == null) {
        _showMessage("No fingerprint registered for this device.");
        setState(() => _isLoading = false);
        return;
      }

      final success = await AuthService.fingerprintLogin(
        fingerprintToken: token,
        deviceId: deviceId,
      );

      if (success) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        _showMessage('Authentication failed. Please try again.');
      }
    } catch (e) {
      _showMessage('An error occurred. Please try again.');
    } finally {
      setState(() => _isLoading = false);
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo or App Icon
                    Container(
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
                      child: Icon(HugeIcons.strokeRoundedLock),
                    ),
                    SizedBox(height: 30),
                    
                    // Welcome Text
                    Text(
                      'Selamat Datang',
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Masuk menggunakan akun kamu',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: Colors.black54,
                      ),
                    ),
                    SizedBox(height: 35),
                    
                    // Username Field
                    TextFormField(
                      controller: _usernameController,
                      style: GoogleFonts.outfit(),
                      decoration: _getInputDecoration(
                        label: 'Username',
                        hint: 'Masukkan username',
                        prefixIcon: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(HugeIcons.strokeRoundedUser03),
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
                        hint: 'Masukkan kata sandi',
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
                    SizedBox(height: 15),
                    
                    // Forgot Password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          foregroundColor: primaryColor,
                          padding: EdgeInsets.zero,
                          minimumSize: Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Lupa Kata Sandi?',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 30),
                    
                    // Login Button
                    Container(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
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
                        child: _isLoading
                            ? SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                'Masuk',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: 20),
                    
                    // Fingerprint Button
                    Container(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton.icon(
                        icon: Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Icon(HugeIcons.strokeRoundedFingerAccess),
                        ),
                        label: Text(
                          'Masuk pakai Fingerprint',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onPressed: _isLoading ? null : _handleFingerprintLogin,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: primaryColor, width: 1.5),
                          foregroundColor: primaryColor,
                          shape: SmoothRectangleBorder(
                            borderRadius: SmoothBorderRadius(
                              cornerRadius: 16,
                              cornerSmoothing: 0.8,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 30),
                    
                    // Sign Up Link
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.center,
                    //   children: [
                    //     Text(
                    //       "Belum punya akun?",
                    //       style: GoogleFonts.outfit(
                    //         color: Colors.black54,
                    //         fontSize: 14,
                    //       ),
                    //     ),
                    //     TextButton(
                    //       onPressed: () {
                    //         Navigator.pushReplacementNamed(context, '/signup');
                    //       },
                    //       style: TextButton.styleFrom(
                    //         foregroundColor: primaryColor,
                    //         padding: EdgeInsets.only(left: 5),
                    //         minimumSize: Size(0, 0),
                    //         tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    //       ),
                    //       child: Text(
                    //         'Daftar',
                    //         style: GoogleFonts.outfit(
                    //           fontWeight: FontWeight.w600,
                    //           fontSize: 14,
                    //         ),
                    //       ),
                    //     ),
                    //   ],
                    // ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}