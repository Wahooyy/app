import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'home.dart';
import '../services/auth.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  Timer? _debounceTimer;
@override
void initState() {
  super.initState();
  // Reset all state variables
  _errorMessage = null;
  _usernameStatus = null;
  _isChecking = false;
  _fingerprintRegistered = false;
} 
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isLoading = false;
  bool _fingerprintRegistered = false;
  final AuthService _authService = AuthService();
  String? _errorMessage;

  // In _SignUpPageState class
bool _isChecking = false;  // Add this to track when checking username
String? _usernameStatus;  // Add this to track username status



  @override
void dispose() {
  _debounceTimer?.cancel();
  // ... your existing dispose code
  super.dispose();
} 

  // Check if device supports biometrics
  Future<bool> _checkBiometrics() async {
    bool canCheckBiometrics = false;
    try {
      canCheckBiometrics = await _localAuth.canCheckBiometrics;
    } catch (e) {
      print("Error checking biometrics: $e");
    }
    return canCheckBiometrics;
  }

  // Get available biometrics
  Future<List<BiometricType>> _getAvailableBiometrics() async {
    List<BiometricType> availableBiometrics = [];
    try {
      availableBiometrics = await _localAuth.getAvailableBiometrics();
    } catch (e) {
      print("Error getting available biometrics: $e");
    }
    return availableBiometrics;
  }

  // Register fingerprint
  Future<void> _registerFingerprint() async {
    try {
      bool canCheckBiometrics = await _checkBiometrics();
      
      if (!canCheckBiometrics) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Device does not support biometric authentication'))
        );
        return;
      }
      
      List<BiometricType> availableBiometrics = await _getAvailableBiometrics();
      print("Available biometrics: $availableBiometrics");

      // Check for fingerprint or face recognition
      bool hasBiometrics = availableBiometrics.contains(BiometricType.fingerprint) || 
                           availableBiometrics.contains(BiometricType.face) ||
                           availableBiometrics.contains(BiometricType.strong);
                           
      if (!hasBiometrics) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No biometric authentication available on this device'))
        );
        return;
      }

      bool authenticated = await _localAuth.authenticate(
        localizedReason: 'Scan your fingerprint to register',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated) {
        setState(() {
          _fingerprintRegistered = true;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Biometric authentication registered successfully'))
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Biometric authentication registration failed'))
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'))
      );
    }
  }

  // Check username availability while typing
  Future<void> _checkUsername(String username) async {
  if (username.length > 3) {
    setState(() {
      _isChecking = true;
      _errorMessage = null;
      _usernameStatus = null;
    });

    bool isAvailable = await _authService.isUsernameAvailable(username);
    
    setState(() {
      _isChecking = false;
      if (!isAvailable) {
        _errorMessage = 'Username already exists';
        _usernameStatus = 'exists';
      } else {
        _errorMessage = null;
        _usernameStatus = 'available';
      }
    });
    
    print('Username "$username" availability check result: $isAvailable');
    print('Current error message: $_errorMessage');
    print('Current username status: $_usernameStatus');
  }
}

  // Complete sign up process
  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      if (!_fingerprintRegistered) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please register your biometric authentication'))
        );
        return;
      }

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        // Final check for username availability before registration
        bool usernameAvailable = await _authService.isUsernameAvailable(_usernameController.text);
        if (!usernameAvailable) {
          setState(() {
            _errorMessage = 'Username already exists. Please choose another one.';
            _isLoading = false;
          });
          return;
        }

        // Register the user
        final result = await _authService.register(
          _nameController.text,
          _usernameController.text,
          _passwordController.text,
        );
        
        if (result['success']) {
          // Proceed with fingerprint registration
          bool fingerprintRegistered = await _authService.registerFingerprint(_usernameController.text);
          if (fingerprintRegistered) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('isLoggedIn', true);
            await prefs.setString('username', _usernameController.text);
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Registration successful'))
            );
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => HomePage())
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Biometric registration failed. Please try again.'))
            );
          }
        } else {
          setState(() {
            _errorMessage = result['message'] ?? 'Registration failed. Please try again.';
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Error: ${e.toString()}';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign Up'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_errorMessage != null)
                  Container(
                    padding: EdgeInsets.all(8),
                    margin: EdgeInsets.only(bottom: 16),
                    color: Colors.red.shade100,
                    width: double.infinity,
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade900),
                    ),
                  ),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
  controller: _usernameController,
  decoration: InputDecoration(
    labelText: 'Username',
    border: OutlineInputBorder(),
    suffixIcon: _isChecking 
        ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
        : _usernameStatus == 'available'
            ? Icon(Icons.check, color: Colors.green)
            : _usernameStatus == 'exists'
                ? Icon(Icons.close, color: Colors.red)
                : null,
  ),
  onChanged: (value) {
    // Add a delay to avoid too many API calls
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(Duration(milliseconds: 500), () {
      _checkUsername(value);
    });
  },
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a username';
    }
    if (_usernameStatus == 'exists') {
      return 'Username already exists';
    }
    return null;
  },
),
                SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: Icon(_fingerprintRegistered ? Icons.check : Icons.fingerprint),
                  label: Text(_fingerprintRegistered ? 'Biometric Registered' : 'Register Biometric'),
                  onPressed: _fingerprintRegistered ? null : _registerFingerprint,
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                    backgroundColor: _fingerprintRegistered ? Colors.green : null,
                  ),
                ),
                SizedBox(height: 16),
                _isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _signUp,
                      child: Text('Sign Up'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}