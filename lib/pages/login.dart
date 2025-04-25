// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'daftar.dart';
import 'home.dart';
import '../services/auth.dart';

class SignInPage extends StatefulWidget {
  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
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

  // Authenticate with fingerprint
  Future<bool> _authenticateWithFingerprint() async {
    bool authenticated = false;
    try {
      authenticated = await _localAuth.authenticate(
        localizedReason: 'Scan your fingerprint to authenticate',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      print("Error authenticating with fingerprint: $e");
    }
    return authenticated;
  }

  // Login with username and password
  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        bool success = await _authService.login(
          _usernameController.text,
          _passwordController.text,
        );
        
        if (success) {
          // Save login state
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('username', _usernameController.text);
          
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => HomePage())
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invalid username or password'))
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'))
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Login with fingerprint
  Future<void> _loginWithFingerprint() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      bool canCheckBiometrics = await _checkBiometrics();
      
      if (!canCheckBiometrics) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Device does not support biometric authentication'))
        );
        return;
      }
      
      List<BiometricType> availableBiometrics = await _getAvailableBiometrics();
      
      if (!availableBiometrics.contains(BiometricType.fingerprint)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fingerprint authentication not available'))
        );
        return;
      }
      
      bool authenticated = await _authenticateWithFingerprint();
      
      if (authenticated) {
        // Get saved username
        final prefs = await SharedPreferences.getInstance();
        String? username = prefs.getString('username');
        
        if (username != null) {
          bool success = await _authService.fingerprintLogin(username);
          
          if (success) {
            await prefs.setBool('isLoggedIn', true);
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => HomePage())
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Fingerprint login failed. Please login with username and password.'))
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No username found. Please login with username and password first.'))
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Authentication failed'))
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'))
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign In'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your username';
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
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              _isLoading
                ? CircularProgressIndicator()
                : Column(
                    children: [
                      ElevatedButton(
                        onPressed: _login,
                        child: Text('Sign In'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 50),
                        ),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: Icon(Icons.fingerprint),
                        label: Text('Sign In with Fingerprint'),
                        onPressed: _loginWithFingerprint,
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 50),
                        ),
                      ),
                    ],
                  ),
              SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => SignUpPage())
                  );
                },
                child: Text('Don\'t have an account? Sign Up'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}