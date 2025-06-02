//auth_service.dart
// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'http://103.76.15.27/api';
  // static const String baseUrl = 'http://10.0.2.2/auth_app_api';
  static int? _userId;
  
  // SharedPreferences keys
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUserId = 'user_id';
  static const String _keyUsername = 'username';
  static const String _keyDeviceId = 'device_id';
  static const String _keyFingerprintToken = 'fingerprint_token';

  // Get stored user ID
  static int? getUserId() {
    return _userId;
  }

  // Check if user is logged in (from SharedPreferences)
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
    
    if (isLoggedIn) {
      // Load user data from SharedPreferences
      _userId = prefs.getInt(_keyUserId);
      print('AuthService: User is logged in with ID: $_userId');
    }
    
    return isLoggedIn;
  }

  // Save login state to SharedPreferences
  static Future<void> _saveLoginState({
    required int userId,
    String? username,
    String? deviceId,
    String? fingerprintToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setInt(_keyUserId, userId);
    
    if (username != null) {
      await prefs.setString(_keyUsername, username);
    }
    if (deviceId != null) {
      await prefs.setString(_keyDeviceId, deviceId);
    }
    if (fingerprintToken != null) {
      await prefs.setString(_keyFingerprintToken, fingerprintToken);
    }
    
    print('AuthService: Login state saved for user ID: $userId');
  }

  // Clear login state from SharedPreferences
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUsername);
    await prefs.remove(_keyDeviceId);
    await prefs.remove(_keyFingerprintToken);
    
    _userId = null;
    print('AuthService: User logged out and login state cleared');
  }

  static void setUserId(int userId) {
    _userId = userId;
  }

  // Get saved credentials for biometric login
  static Future<Map<String, String?>> getSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'username': prefs.getString(_keyUsername),
      'deviceId': prefs.getString(_keyDeviceId),
      'fingerprintToken': prefs.getString(_keyFingerprintToken),
    };
  }

  static Future<bool> login(String username, String password) async {
    print('AuthService: Attempting login for username: $username');
    
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/login.php'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'username': username.trim(),
          'password': password,
        },
      ).timeout(Duration(seconds: 30));

      print('AuthService: Login response status: ${res.statusCode}');
      print('AuthService: Login response body: ${res.body}');

      if (res.statusCode != 200) {
        print('AuthService: HTTP error - Status code: ${res.statusCode}');
        return false;
      }

      if (res.body.isEmpty) {
        print('AuthService: Empty response body');
        return false;
      }

      final data = jsonDecode(res.body);
      
      if (data['success'] == true) {
        _userId = int.tryParse(data['user_id'].toString());
        if (_userId != null) {
          // Save login state to SharedPreferences
          await _saveLoginState(
            userId: _userId!,
            username: username.trim(),
          );
          
          print('AuthService: Login successful, User ID: $_userId');
          return true;
        } else {
          print('AuthService: Failed to parse user_id');
          return false;
        }
      } else {
        print('AuthService: Login failed - ${data['message'] ?? 'Unknown error'}');
        return false;
      }
    } on http.ClientException catch (e) {
      print('AuthService: Network error during login: $e');
      return false;
    } on FormatException catch (e) {
      print('AuthService: JSON decode error during login: $e');
      return false;
    } catch (e) {
      print('AuthService: Unexpected error during login: $e');
      return false;
    }
  }

  // Function to handle fingerprint login
  static Future<bool> fingerprintLogin({
    required int userId,
    required String fingerprintToken,
    required String deviceId,
  }) async {
    print('AuthService: Attempting fingerprint login');
    print('AuthService: User ID: $userId, Device ID: $deviceId');

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/fingerprint_login.php'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'user_id': userId.toString(),
          'fingerprint_token': fingerprintToken,
          'device_id': deviceId,
        },
      ).timeout(Duration(seconds: 30));

      print('AuthService: Fingerprint login response status: ${res.statusCode}');
      print('AuthService: Fingerprint login response body: ${res.body}');

      if (res.statusCode != 200) {
        print('AuthService: HTTP error during fingerprint login');
        return false;
      }

      if (res.body.isEmpty) {
        print('AuthService: Empty response body from fingerprint login');
        return false;
      }

      final data = jsonDecode(res.body);
      bool success = data['success'] == true;
      
      if (success) {
        // Update login state in SharedPreferences
        await _saveLoginState(
          userId: userId,
          deviceId: deviceId,
          fingerprintToken: fingerprintToken,
        );
        
        print('AuthService: Fingerprint login successful');
      } else {
        print('AuthService: Fingerprint login failed - ${data['message'] ?? 'Unknown error'}');
      }
      
      return success;
    } on http.ClientException catch (e) {
      print('AuthService: Network error during fingerprint login: $e');
      return false;
    } on FormatException catch (e) {
      print('AuthService: JSON decode error during fingerprint login: $e');
      return false;
    } catch (e) {
      print('AuthService: Unexpected error during fingerprint login: $e');
      return false;
    }
  }

  static Future<bool> registerWithFingerprint(
    int userId,
    String fingerprintToken,
    String deviceId,
  ) async {
    print('AuthService: Registering fingerprint for user: $userId');
    
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/register_fingerprint.php'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'user_id': userId.toString(),
          'fingerprint_token': fingerprintToken,
          'device_id': deviceId,
        },
      ).timeout(Duration(seconds: 30));

      print('AuthService: Fingerprint registration response status: ${res.statusCode}');
      print('AuthService: Fingerprint registration response body: ${res.body}');

      if (res.statusCode != 200) {
        print('AuthService: HTTP error during fingerprint registration');
        return false;
      }

      if (res.body.isEmpty) {
        print('AuthService: Empty response body from fingerprint registration');
        return false;
      }

      final data = jsonDecode(res.body);
      bool success = data['success'] == true;
      
      if (success) {
        // Save fingerprint data to SharedPreferences
        await _saveLoginState(
          userId: userId,
          deviceId: deviceId,
          fingerprintToken: fingerprintToken,
        );
        
        print('AuthService: Fingerprint registration successful');
      } else {
        print('AuthService: Fingerprint registration failed - ${data['message'] ?? 'Unknown error'}');
      }
      
      return success;
    } on http.ClientException catch (e) {
      print('AuthService: Network error during fingerprint registration: $e');
      return false;
    } on FormatException catch (e) {
      print('AuthService: JSON decode error during fingerprint registration: $e');
      return false;
    } catch (e) {
      print('AuthService: Unexpected error during fingerprint registration: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getFingerprintData(String deviceId) async {
    print('AuthService: Getting fingerprint data for device: $deviceId');
    
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/get_fingerprint_token.php'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {'device_id': deviceId},
      ).timeout(Duration(seconds: 30));

      print('AuthService: Get fingerprint data response status: ${res.statusCode}');
      print('AuthService: Get fingerprint data response body: ${res.body}');

      if (res.statusCode != 200) {
        print('AuthService: HTTP error getting fingerprint data');
        return null;
      }

      if (res.body.isEmpty) {
        print('AuthService: Empty response body when getting fingerprint data');
        return null;
      }

      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        return {
          'user_id': int.tryParse(data['user_id'].toString()) ?? 0,
          'fingerprint_token': data['fingerprint_token']?.toString() ?? '',
        };
      } else {
        print('AuthService: Failed to get fingerprint data - ${data['message'] ?? 'Unknown error'}');
        return null;
      }
    } on http.ClientException catch (e) {
      print('AuthService: Network error getting fingerprint data: $e');
      return null;
    } on FormatException catch (e) {
      print('AuthService: JSON decode error getting fingerprint data: $e');
      return null;
    } catch (e) {
      print('AuthService: Unexpected error getting fingerprint data: $e');
      return null;
    }
  }

  // Function to get the fingerprint token from the database based on device ID
  static Future<String> getFingerprintToken(String deviceId, int userId) async {
    
    final res = await http.post(
      Uri.parse('$baseUrl/get_fingerprint_token.php'),
      body: {
        'device_id': deviceId,
        'user_id': userId.toString(),
      },
    );

    final data = jsonDecode(res.body);
    if (data['success'] == true) {
      return data['fingerprint_token']; // Return the fingerprint token
    }
    return '';
  }

  static Future<Map<String, dynamic>> submitAttendance(String locationCode, String mode) async {
    print('Scanned location code: $locationCode');
    
    try {
      // Get device information
      final deviceInfo = DeviceInfoPlugin();
      String deviceId = '';

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? 'unknown';
      }

      print('Device ID: $deviceId');

      // Check location permission
      PermissionStatus permission = await Permission.location.request();
      if (permission.isDenied) {
        return {
          'success': false,
          'error': 'Location permission denied. Please allow location access in Settings.'
        };
      } else if (permission.isPermanentlyDenied) {
        return {
          'success': false,
          'error': 'Location permission permanently denied. Please enable it in Settings.'
        };
      }

      // Get current location
      Position position;
      try {
        // Check if location services are enabled
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          return {
            'success': false,
            'error': 'Location services are disabled. Please enable location services.'
          };
        }

        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        );
        print('Location: ${position.latitude}, ${position.longitude}');
      } catch (e) {
        print("Failed to get location: $e");
        return {
          'success': false,
          'error': 'Failed to get location: ${e.toString()}'
        };
      }

      // Prepare the POST body
      final postBody = {
        'location_code': locationCode,
        'device_id': deviceId,
        'latitude': position.latitude.toString(),
        'longitude': position.longitude.toString(),
        'mode': mode,
      };

      print('POST body: $postBody');

      // Make HTTP request with timeout
      final res = await http.post(
        Uri.parse('$baseUrl/submit_attendance.php'),
        body: postBody,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      ).timeout(Duration(seconds: 30));

      print('HTTP Status Code: ${res.statusCode}');
      print('API raw response: "${res.body}"');

      // Check HTTP status code
      if (res.statusCode != 200) {
        return {
          'success': false,
          'error': 'Server error: HTTP ${res.statusCode}'
        };
      }

      // Check if response is empty
      // ignore: unnecessary_null_comparison
      if (res.body == null || res.body.trim().isEmpty) {
        print('API returned empty response!');
        return {
          'success': false,
          'error': 'Server returned empty response'
        };
      }

      // Try to decode JSON response
      try {
        final data = jsonDecode(res.body);
        print('API decoded response: $data');
        
        if (data['success'] == true) {
          return {'success': true};
        } else {
          // Server returned error message
          String errorMsg = data['message'] ?? data['error'] ?? 'Unknown server error';
          return {
            'success': false,
            'error': errorMsg
          };
        }
      } catch (e) {
        print('Error decoding API response: $e');
        print('Raw response: "${res.body}"');
        return {
          'success': false,
          'error': 'Invalid response format from server'
        };
      }
    } catch (e) {
      print('Unexpected error in submitAttendance: $e');
      return {
        'success': false,
        'error': 'Unexpected error: ${e.toString()}'
      };
    }
  }
  
  static Future<List<Map<String, dynamic>>> getUserList() async {
    final res = await http.get(Uri.parse('$baseUrl/get_user_list.php'));

    print('RESPONSE STATUS: ${res.statusCode}');
    print('RESPONSE BODY: ${res.body}');

    try {
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        List<dynamic> users = data['users'];
        return users.cast<Map<String, dynamic>>();
      } else {
        return [];
      }
    } catch (e) {
      print('JSON decode error: $e');
      return [];
    }
  }

    // Fetch user profile data
    static Future<Map<String, dynamic>?> getUserProfile() async {
      if (_userId == null) {
        print('getUserProfile: No user ID available');
        return null;
      }
      
      print('getUserProfile: Requesting profile for user ID: $_userId');
      
      try {
        final res = await http.post(
          Uri.parse('$baseUrl/get_user_profile.php'),
          body: {'user_id': _userId.toString()},
        );
        
        print('getUserProfile: Response status code: ${res.statusCode}');
        print('getUserProfile: Response body: ${res.body}');
        
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          print('getUserProfile: Successfully loaded user data');
          return data['user_data'];
        } else {
          print('getUserProfile: API returned success=false. Message: ${data['message']}');
          return null;
        }
      } catch (e) {
        print('getUserProfile: Exception occurred: $e');
        return null;
      }
    }
    static Future<Map<String, dynamic>> getTodayCheckinStatus() async {
    final deviceInfo = DeviceInfoPlugin();
    String deviceId = '';

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      deviceId = androidInfo.id;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      deviceId = iosInfo.identifierForVendor ?? 'unknown';
    }

    final res = await http.post(
      Uri.parse('$baseUrl/get_today_checkin.php'),
      body: {'device_id': deviceId},
    );

    // ignore: unnecessary_null_comparison
    if (res.body == null || res.body.trim().isEmpty) {
      return {'success': false, 'checked_in': false};
    }

    try {
      final data = jsonDecode(res.body);
      return data;
    } catch (e) {
      print('Error decoding checkin status: $e');
      return {'success': false, 'checked_in': false};
    }
  }

  // Updated getAttendanceHistory method for AuthService
  static Future<List<Map<String, dynamic>>> getAttendanceHistory(
      int userId, String startDate, String endDate) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/attendance_history.php'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'karyawan_id': userId.toString(),
          'start_date': startDate,
          'end_date': endDate,
        },
      );

      print('Attendance History Request:');
      print('URL: $baseUrl/attendance_history.php');
      print('Body: karyawan_id=$userId, start_date=$startDate, end_date=$endDate');
      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      // Check if response is empty or null
      if (response.body.isEmpty || response.body.trim().isEmpty) {
        print('Empty response body');
        return [];
      }

      // Check for HTTP errors
      if (response.statusCode != 200) {
        print('HTTP Error: ${response.statusCode}');
        return [];
      }

      // Try to decode JSON
      final data = jsonDecode(response.body);
      
      // Check if response structure is correct
      if (data is! Map<String, dynamic>) {
        print('Invalid response format: not a map');
        return [];
      }

      // Check success status
      if (data['success'] != true) {
        print('API returned success: false');
        print('Message: ${data['message'] ?? 'No message'}');
        return [];
      }

      // Check if history exists and is a list
      if (data['history'] == null) {
        print('No history key in response');
        return [];
      }

      if (data['history'] is! List) {
        print('History is not a list');
        return [];
      }

      // Convert to List<Map<String, dynamic>>
      final List<Map<String, dynamic>> history = 
          List<Map<String, dynamic>>.from(data['history']);

      print('Successfully parsed ${history.length} attendance records');
      return history;

    } catch (e, stackTrace) {
      print('Error in getAttendanceHistory: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  static Future<List<String>> getUserRegisteredDevices(int userId) async {
    print('AuthService: Getting registered devices for user: $userId');
    
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/get_user_devices.php'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {'user_id': userId.toString()},
      ).timeout(Duration(seconds: 30));

      print('AuthService: Get user devices response status: ${res.statusCode}');
      print('AuthService: Get user devices response body: ${res.body}');

      if (res.statusCode != 200 || res.body.isEmpty) {
        return [];
      }

      final data = jsonDecode(res.body);
      if (data['success'] == true && data['devices'] != null) {
        return List<String>.from(data['devices']);
      }
      return [];
    } catch (e) {
      print('AuthService: Error getting user devices: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getLatestAttendance(int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/attendance_latest.php'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'karyawan_id': userId.toString(),
        },
      );

      if (response.statusCode != 200 || response.body.isEmpty) {
        return [];
      }

      final data = jsonDecode(response.body);
      if (data['success'] != true || data['history'] == null || data['history'] is! List) {
        return [];
      }

      return List<Map<String, dynamic>>.from(data['history']);
    } catch (e) {
      return [];
    }
  }

}