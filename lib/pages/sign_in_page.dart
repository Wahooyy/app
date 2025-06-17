// lib/pages/sign_in_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import 'face_registration_page.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

enum NotificationType { success, error, warning, info }

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
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

  // Enhanced notification system with smooth rounded corners
  void showEnhancedMessage(String message, NotificationType type) {
    // Remove any existing snackbar first
    ScaffoldMessenger.of(context).clearSnackBars();
    
    Color backgroundColor, borderColor;
    IconData icon;
    String title;
    
    switch (type) {
      case NotificationType.success:
        backgroundColor = Color(0xFFF0FDF4); // Light green
        borderColor = Color(0xFF22C55E); // Green
        icon = HugeIcons.strokeRoundedCheckmarkCircle02;
        title = "Sukses";
        break;
      case NotificationType.error:
        backgroundColor = Color(0xFFFEF2F2); // Light red
        borderColor = Color(0xFFEF4444); // Red
        icon = HugeIcons.strokeRoundedAlert02;
        title = "Error";
        break;
      case NotificationType.warning:
        backgroundColor = Color(0xFFFFFBEB); // Light yellow
        borderColor = Color(0xFFF59E0B); // Yellow/Orange
        icon = HugeIcons.strokeRoundedAlert01;
        title = "Peringatan";
        break;
      case NotificationType.info:
        backgroundColor = Color(0xFFF0F9FF); // Light blue
        borderColor = Color(0xFF3B82F6); // Blue
        icon = HugeIcons.strokeRoundedInformationCircle;
        title = "Info";
        break;
    }

    final snackBar = SnackBar(
      content: Container(
        padding: EdgeInsets.all(16),
        decoration: ShapeDecoration(
          color: backgroundColor,
          shape: SmoothRectangleBorder(
            borderRadius: SmoothBorderRadius(
              cornerRadius: 16,
              cornerSmoothing: 1,
            ),
            side: BorderSide(color: borderColor, width: 1.5),
          ),
        ),
        child: Row(
          children: [
            // Left Icon with smooth rounded container
            Container(
              padding: EdgeInsets.all(8),
              decoration: ShapeDecoration(
                color: borderColor.withOpacity(0.1),
                shape: SmoothRectangleBorder(
                  borderRadius: SmoothBorderRadius(
                    cornerRadius: 12,
                    cornerSmoothing: 1,
                  ),
                ),
              ),
              child: Icon(
                icon,
                color: borderColor,
                size: 20,
              ),
            ),
            SizedBox(width: 14),
            
            // Title and Message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: borderColor,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    message,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            
            // Close Button - no background color
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
              child: Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  HugeIcons.strokeRoundedCancel01,
                  color: borderColor.withOpacity(0.7),
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.all(16),
      duration: Duration(seconds: 4),
      // Enhanced animation with smooth curve
      animation: CurvedAnimation(
        parent: ModalRoute.of(context)!.animation!,
        curve: Curves.elasticOut,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  // Helper methods for different notification types
  void showMessage(String message) {
    showEnhancedMessage(message, NotificationType.info);
  }

  void showSuccessMessage(String message) {
    showEnhancedMessage(message, NotificationType.success);
  }

  void showErrorMessage(String message) {
    showEnhancedMessage(message, NotificationType.error);
  }

  void showWarningMessage(String message) {
    showEnhancedMessage(message, NotificationType.warning);
  }

  void showInfoMessage(String message) {
    showEnhancedMessage(message, NotificationType.info);
  }



  Future<void> _handleLogin() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      showWarningMessage('Masukkan username dan password');
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      // Show loading message
      showInfoMessage('Sedang memproses login...');
      
      final response = await AuthService.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );
      
      if (!mounted) return;
      
      if (response['success'] == true) {
        final userId = response['user_id'] as int?;
        final hasFace = response['has_face'] as bool? ?? false;
        
        if (userId != null) {
          // If user doesn't have face registered, navigate to face registration
          if (!hasFace) {
            if (mounted) {
              showInfoMessage('Pendaftaran wajah diperlukan');
              final success = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) => FaceRegistrationPage(),
                ),
              );
              
              if (success == true) {
                // Face registration successful, proceed to home
                if (mounted) {
                  showSuccessMessage('Wajah berhasil didaftarkan!');
                  Navigator.pushReplacementNamed(context, '/home');
                }
              } else {
                // Face registration failed or was cancelled
                showWarningMessage('Pendaftaran wajah dibutuhkan untuk melanjutkan');
                await AuthService.logout();
              }
            }
          } else {
            // User has face registered, proceed to home
            if (mounted) {
              showSuccessMessage('Login berhasil!');
              Navigator.pushReplacementNamed(context, '/home');
            }
          }
        } else {
          showErrorMessage('Gagal memproses data pengguna');
        }
      } else {
        // Show error message from API or default message
        final errorMessage = response['message'] as String? ?? 'Username atau password salah';
        showErrorMessage(errorMessage);
      }
    } on TimeoutException catch (e) {
      showErrorMessage('Koneksi timeout. Silakan coba lagi.');
    } on http.ClientException catch (e) {
      showErrorMessage('Tidak dapat terhubung ke server. Periksa koneksi internet Anda.');
    } catch (e) {
      showErrorMessage('Terjadi kesalahan. Silakan coba lagi.');
      print('Login error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
      hintStyle: GoogleFonts.outfit(color: Colors.grey.shade400),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Color(0xFF143CFF), width: 2),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: EdgeInsets.symmetric(vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Color(0xFF143CFF);

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
                    // Align(
                    //   alignment: Alignment.centerRight,
                    //   child: TextButton(
                    //     onPressed: () {},
                    //     style: TextButton.styleFrom(
                    //       foregroundColor: primaryColor,
                    //       padding: EdgeInsets.zero,
                    //       minimumSize: Size(0, 0),
                    //       tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    //     ),
                    //     child: Text(
                    //       'Lupa Kata Sandi?',
                    //       style: GoogleFonts.outfit(
                    //         fontSize: 14,
                    //         fontWeight: FontWeight.w500,
                    //       ),
                    //     ),
                    //   ),
                    // ),
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

                    // Face Login Button
                    // if (false) // Keep the button structure but hide it for now
                    // Container(
                    //   width: double.infinity,
                    //   height: 56,
                    //   child: OutlinedButton.icon(
                    //     icon: Padding(
                    //       padding: EdgeInsets.only(right: 8),
                    //       child: Icon(HugeIcons.strokeRoundedFaceId),
                    //     ),
                    //     label: Text(
                    //       'Masuk dengan Wajah',
                    //       style: GoogleFonts.outfit(
                    //         fontSize: 15,
                    //         fontWeight: FontWeight.w500,
                    //       ),
                    //     ),
                    //     onPressed: null,
                    //     style: OutlinedButton.styleFrom(
                    //       side: BorderSide(color: primaryColor, width: 1.5),
                    //       foregroundColor: primaryColor,
                    //       shape: SmoothRectangleBorder(
                    //         borderRadius: SmoothBorderRadius(
                    //           cornerRadius: 16,
                    //           cornerSmoothing: 0.8,
                    //         ),
                    //       ),
                    //     ),
                    //   ),
                    // ),
                    // SizedBox(height: 30),

                    // Sign Up Link (commented out as in original)
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