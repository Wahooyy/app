//auth_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class AuthService {
  static const String baseUrl = 'http://103.76.15.27/api';
  // static const String baseUrl = 'http://10.0.2.2/auth_app_api';
  static int? _userId;
  // Get stored user ID
  static int? getUserId() {
    return _userId;
  }
  // Clear user ID on logout
  static void logout() {
    _userId = null;
  }

  static void setUserId(int userId) {
    _userId = userId;
  }

  static Future<bool> login(String username, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/login.php'),
      body: {'username': username, 'password': password},
    );

    try {
      final data = jsonDecode(res.body);
      print('login: Response data: $data');
      
      if (data['success'] == true) {
        _userId = data['user_id'];
        print('login: User ID set to: $_userId');
        return true;
      }
      print('login: Authentication failed');
      return false;
    } catch (e) {
      print('login: JSON decode error: $e');
      return false;
    }
  }

  // Function to handle fingerprint login
  static Future<bool> fingerprintLogin({
    required int userId,
    required String fingerprintToken,
    required String deviceId,
  }) async {
    print('fingerprintLogin POST body: {user_id: $userId, fingerprint_token: $fingerprintToken, device_id: $deviceId}');

    final res = await http.post(
      Uri.parse('$baseUrl/fingerprint_login.php'),
      body: {
        'user_id': userId.toString(),
        'fingerprint_token': fingerprintToken,
        'device_id': deviceId,
      },
    );

    print('fingerprintLogin response: "${res.body}"');
    final data = jsonDecode(res.body);
    return data['success'] == true;
  }

  static Future<bool> registerWithFingerprint(
    int userId,
    String fingerprintToken,
    String deviceId,
  ) async {
    final fingerprintRes = await http.post(
      Uri.parse('$baseUrl/register_fingerprint.php'),
      body: {
        'user_id': userId.toString(),
        'fingerprint_token': fingerprintToken,
        'device_id': deviceId,
      },
    );
    final fpData = jsonDecode(fingerprintRes.body);
    return fpData['success'] == true;
  }

  static Future<Map<String, dynamic>?> getFingerprintData(String deviceId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/get_fingerprint_token.php'),
      body: {'device_id': deviceId},
    );

    final data = jsonDecode(res.body);
    if (data['success'] == true) {
      return {
        'user_id': int.parse(data['user_id'].toString()),
        'fingerprint_token': data['fingerprint_token'],
      };
    }
    return null;
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

  static Future<bool> submitAttendance(String locationCode,String mode) async {
    print('Scanned location code: $locationCode'); // <-- Add this line
    final deviceInfo = DeviceInfoPlugin();
    String deviceId = '';

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      // deviceId = androidInfo.id ?? 'unknown';
      deviceId = androidInfo.id;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      deviceId = iosInfo.identifierForVendor ?? 'unknown';
    }

    // Meminta izin lokasi
    PermissionStatus permission = await Permission.location.request();
    if (permission.isDenied || permission.isPermanentlyDenied) {
      // Jika izin ditolak atau tidak permanen, beri tahu pengguna
      return false;
    }

    // Ambil lokasi
    Position position;
    try {
      position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      print("Gagal mengambil lokasi: $e");
      return false;
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

    final res = await http.post(
      Uri.parse('$baseUrl/submit_attendance.php'),
      body: postBody,
    );

    print('API raw response: "${res.body}"');

    if (res.body == null || res.body.trim().isEmpty) {
      print('API returned empty response!');
      return false;
    }

    try {
      final data = jsonDecode(res.body);
      print('API decoded response: $data');
      return data['success'] == true;
    } catch (e) {
      print('Error decoding API response: $e');
      print('Raw response: "${res.body}"');
      return false;
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
}
