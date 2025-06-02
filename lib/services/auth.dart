import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';

class AuthService {
  final String apiUrl = 'https://192.168.4.25/auth_app_api';
  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();
  final Uuid _uuid = Uuid();

  // Enhanced debug function
void debugLog(String message) {
  print("DEBUG: $message");
  // You could also write to a file or send to a remote logging service
}

  // Get device ID based on platform
  Future<String> _getDeviceId() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfoPlugin.androidInfo;
        return androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfoPlugin.iosInfo;
        return iosInfo.identifierForVendor ?? "Unknown";
      } else {
        throw Exception('Platform not supported');
      }
    } catch (e) {
      print('Error getting device ID: $e');
      return "Error";
    }
  }

  // Check if username is available
  Future<bool> isUsernameAvailable(String username) async {
  try {
    final response = await http.get(
      Uri.parse('$apiUrl/check_username.php?username=$username'),
    );

    print('Full username check response: ${response.body}');
    
    if (response.statusCode == 200) {
      // Force a new instance of the parsed JSON data to avoid caching issues
      final responseData = json.decode(response.body) as Map<String, dynamic>;
      
      print('Parsed username check: $responseData');
      print('isAvailable value: ${responseData['isAvailable']}');
      print('isAvailable type: ${responseData['isAvailable'].runtimeType}');
      
      // Check response explicitly with strict equality
      if (responseData.containsKey('isAvailable')) {
        // Convert to boolean explicitly to avoid any type issues
        return responseData['isAvailable'] == true;
      } else {
        print('Missing isAvailable key in response');
        return false;
      }
    } else {
      print('Server error: ${response.statusCode}');
      return false;
    }
  } catch (e) {
    print('Error checking username: $e');
    return false;
  }
}

  // Login with username and password
  Future<bool> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/login.php'),
        body: {
          'username': username,
          'password': password,
        },
      );

      print('Login response: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['success'] == true;
      } else {
        print('Login error: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  // Register a new user
  Future<Map<String, dynamic>> register(
    String name,
    String username,
    String password,
  ) async {
    try {
      print('Registering user: $username');
      final response = await http.post(
        Uri.parse('$apiUrl/register.php'),
        body: {
          'name': name,
          'username': username,
          'password': password,
        },
      );

      print('Register response: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'success': responseData['success'] == true,
          'message': responseData['message'] ?? 'Unknown response',
          'data': responseData
        };
      } else {
        print('Registration error: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Registration error: $e');
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  // Register fingerprint
  Future<bool> registerFingerprint(String username) async {
    try {
      final deviceId = await _getDeviceId();
      final fingerprintToken = _uuid.v4(); // Generate UUID as fingerprint token

      final response = await http.post(
        Uri.parse('$apiUrl/register_fingerprint.php'),
        body: {
          'username': username,
          'fingerprint_token': fingerprintToken,
          'device_id': deviceId,
        },
      );

      print('Fingerprint registration response: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['success'] == true;
      } else {
        print('Fingerprint registration error: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Fingerprint registration error: $e');
      return false;
    }
  }

  // Login with fingerprint
  Future<bool> fingerprintLogin(String username) async {
    try {
      final deviceId = await _getDeviceId();

      final response = await http.post(
        Uri.parse('$apiUrl/fingerprint_login.php'),
        body: {
          'username': username,
          'device_id': deviceId,
        },
      );

      print('Fingerprint login response: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['success'] == true;
      } else {
        print('Fingerprint login error: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Fingerprint login error: $e');
      return false;
    }
  }
}