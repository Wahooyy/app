// lib/pages/sign_in_page.dart
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import '../services/auth_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:uuid/uuid.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = LocalAuthentication();
  final _uuid = Uuid();
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
        backgroundColor: Color(0xFF143CFF),
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

  // Get user-friendly biometric type string
  Future<String> _getBiometricTypeString() async {
    try {
      List<BiometricType> availableBiometrics = await _auth.getAvailableBiometrics();
      
      if (Platform.isIOS) {
        if (availableBiometrics.contains(BiometricType.face)) {
          return 'Face ID';
        } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
          return 'Touch ID';
        } else if (availableBiometrics.contains(BiometricType.strong)) {
          return 'Biometric ID';
        }
      } else if (Platform.isAndroid) {
        if (availableBiometrics.contains(BiometricType.fingerprint)) {
          return 'Fingerprint';
        } else if (availableBiometrics.contains(BiometricType.face)) {
          return 'Face Recognition';
        } else if (availableBiometrics.contains(BiometricType.strong)) {
          return 'Biometric';
        }
      }
      return 'Biometric';
    } catch (e) {
      print('Error getting biometric type: $e');
      return 'Biometric';
    }
  }

  // Check if biometric authentication is available
  Future<bool> _isBiometricAvailable() async {
    try {
      bool canCheckBiometrics = await _auth.canCheckBiometrics;
      if (!canCheckBiometrics) return false;

      List<BiometricType> availableBiometrics = await _auth.getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } catch (e) {
      print('Error checking biometric availability: $e');
      return false;
    }
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
        // Get device info and device ID
        final deviceInfo = DeviceInfoPlugin();
        String deviceId = '';
        
        if (Platform.isAndroid) {
          AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
          deviceId = androidInfo.id;
        } else if (Platform.isIOS) {
          IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
          deviceId = iosInfo.identifierForVendor ?? '';
        } else {
          _showMessage('Unsupported device');
          setState(() => _isLoading = false);
          return;
        }

        // Check if biometric is registered
        final userId = AuthService.getUserId();
        if (userId == null) {
          _showMessage('User ID not found.');
          setState(() => _isLoading = false);
          return;
        }

        final token = await AuthService.getFingerprintToken(deviceId, userId);
        if (token != null && token.isNotEmpty) {
          // Biometric already registered, go to home
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          // Check if biometric is available before prompting registration
          bool biometricAvailable = await _isBiometricAvailable();
          if (biometricAvailable) {
            // Prompt biometric registration
            bool registered = await _registerBiometric(
              deviceId,
              username,
              password,
            );
            if (registered) {
              String biometricType = await _getBiometricTypeString();
              _showMessage('$biometricType registered successfully!');
              Navigator.pushReplacementNamed(context, '/home');
            } else {
              _showMessage('Biometric registration failed or cancelled.');
              Navigator.pushReplacementNamed(context, '/home');
            }
          } else {
            // No biometric available, just go to home
            Navigator.pushReplacementNamed(context, '/home');
          }
        }
      } else {
        _showMessage('Login failed. Please check your credentials.');
      }
    } catch (e) {
      print('Login error: $e');
      _showMessage('Ada error. Coba lagi nanti.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _registerBiometric(
    String deviceId,
    String username,
    String password,
  ) async {
    try {
      // Check available biometrics
      bool canCheckBiometrics = await _auth.canCheckBiometrics;
      if (!canCheckBiometrics) {
        _showMessage('Device does not support biometric authentication');
        return false;
      }

      List<BiometricType> availableBiometrics = await _auth.getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        _showMessage('No supported biometric found.');
        return false;
      }

      String biometricType = await _getBiometricTypeString();

      // Prompt user for biometric registration
      bool authenticated = await _auth.authenticate(
        localizedReason: Platform.isIOS 
          ? 'Set up $biometricType for secure and convenient sign in'
          : 'Register your biometric for secure login',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          sensitiveTransaction: true,
        ),
      );

      if (!authenticated) {
        print('Biometric registration authentication failed');
        return false;
      }

      // Generate a unique fingerprint token
      String fingerprintToken = _uuid.v4();
      final userId = AuthService.getUserId();
      if (userId == null) {
        _showMessage('User ID not found.');
        return false;
      }

      // Register biometric with backend
      bool registered = await AuthService.registerWithFingerprint(
        userId,
        fingerprintToken,
        deviceId,
      );

      if (registered) {
        print('Biometric registration successful');
      } else {
        print('Biometric registration failed on server');
      }

      return registered;
    } catch (e) {
      print('Error during biometric registration: $e');
      _showMessage('Error during biometric registration.');
      return false;
    }
  }

  Future<void> _handleBiometricLogin() async {
    setState(() => _isLoading = true);

    try {
      // Check if biometrics are available
      bool canCheckBiometrics = await _auth.canCheckBiometrics;
      if (!canCheckBiometrics) {
        _showMessage('Biometric authentication not available on this device');
        setState(() => _isLoading = false);
        return;
      }

      List<BiometricType> availableBiometrics = await _auth.getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        _showMessage('No biometric authentication methods available');
        setState(() => _isLoading = false);
        return;
      }

      // Get the biometric type string for user-friendly messages
      String biometricType = await _getBiometricTypeString();

      // Step 1: Biometric Authentication
      final authenticated = await _auth.authenticate(
        localizedReason: Platform.isIOS 
          ? 'Use $biometricType to sign in to your account'
          : 'Authenticate to continue',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          sensitiveTransaction: true,
        ),
      );

      if (!authenticated) {
        _showMessage("$biometricType authentication failed. Please try again.");
        setState(() => _isLoading = false);
        return;
      }

      // Step 2: Get Device ID
      final deviceInfo = DeviceInfoPlugin();
      String deviceId = '';

      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? '';
      } else {
        _showMessage('Unsupported device');
        setState(() => _isLoading = false);
        return;
      }

      // Step 3: Get Fingerprint Data (token + user_id)
      final fingerprintData = await AuthService.getFingerprintData(deviceId);

      if (fingerprintData == null ||
          fingerprintData['fingerprint_token'] == null ||
          fingerprintData['fingerprint_token'].toString().isEmpty) {
        _showMessage("No $biometricType registered for this device.");
        setState(() => _isLoading = false);
        return;
      }

      final int userId = fingerprintData['user_id'];
      final String token = fingerprintData['fingerprint_token'];

      // Step 4: Attempt Fingerprint Login
      final success = await AuthService.fingerprintLogin(
        userId: userId,
        fingerprintToken: token,
        deviceId: deviceId,
      );

      if (success) {
        AuthService.setUserId(userId);
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        _showMessage('Authentication failed. Please try again.');
      }
    } catch (e) {
      print('Biometric login error: $e');
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

                    // Biometric Button (dynamically shows Face ID or Touch ID)
                    FutureBuilder<String>(
                      future: _getBiometricTypeString(),
                      builder: (context, snapshot) {
                        String biometricType = snapshot.data ?? 'Biometric';
                        IconData biometricIcon = Platform.isIOS && biometricType == 'Face ID'
                            ? HugeIcons.strokeRoundedFaceId
                            : HugeIcons.strokeRoundedFingerAccess;
                        
                        return Container(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton.icon(
                            icon: Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: Icon(biometricIcon),
                            ),
                            label: Text(
                              'Masuk pakai $biometricType',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            onPressed: _isLoading ? null : _handleBiometricLogin,
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
                        );
                      },
                    ),
                    SizedBox(height: 30),

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