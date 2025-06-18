//auth_service.dart
// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:http_parser/http_parser.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'http://103.76.15.27/api';
  // static const String baseUrl = 'http://10.0.2.2/auth_app_api';
  // static const String baseUrl = 'http://192.168.68.100/auth_app_api';
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

  static Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    print('AuthService: Attempting login for username: $username');

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/login.php'),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
            },
            body: {'username': username.trim(), 'password': password},
          )
          .timeout(const Duration(seconds: 30));

      print('AuthService: Login response status: ${response.statusCode}');
      print('AuthService: Login response body: ${response.body}');

      if (response.statusCode != 200) {
        print('AuthService: HTTP error - Status code: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Server error. Please try again later.',
        };
      }

      if (response.body.isEmpty) {
        print('AuthService: Empty response body');
        return {'success': false, 'message': 'Empty response from server'};
      }

      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        // Get SharedPreferences instance
        final prefs = await SharedPreferences.getInstance();

        // Save JWT token if it exists in the response
        if (data['token'] != null) {
          await prefs.setString('auth_token', data['token']);
          print('AuthService: JWT token saved to SharedPreferences');
        }

        _userId = int.tryParse(data['user_id']?.toString() ?? '');
        if (_userId != null) {
          // Save login state to SharedPreferences
          await _saveLoginState(userId: _userId!, username: username.trim());

          print('AuthService: Login successful, User ID: $_userId');

          // Check if user has registered face
          bool hasFace = false;
          try {
            hasFace = await hasRegisteredFace(_userId!);
            print(
              'AuthService: User $_userId face registration status: $hasFace',
            );
          } catch (e) {
            print('AuthService: Error checking face registration: $e');
            // Continue with login even if face check fails
            hasFace = false;
          }

          return {
            'success': true,
            'user_id': _userId,
            'has_face': hasFace,
            'message': 'Login successful',
          };
        } else {
          print('AuthService: Failed to parse user_id');
          return {'success': false, 'message': 'Invalid user data received'};
        }
      } else {
        print(
          'AuthService: Login failed - ${data['message'] ?? 'Unknown error'}',
        );
        return {
          'success': false,
          'message': data['message'] ?? 'Unknown error',
        };
      }
    } on http.ClientException catch (e) {
      print('AuthService: Network error during login: $e');
      return {'success': false, 'message': 'Network error'};
    } on FormatException catch (e) {
      print('AuthService: JSON decode error during login: $e');
      return {'success': false, 'message': 'Invalid response format'};
    } catch (e) {
      print('AuthService: Unexpected error during login: $e');
      return {'success': false, 'message': 'Unexpected error'};
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
      final res = await http
          .post(
            Uri.parse('$baseUrl/fingerprint_login.php'),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: {
              'user_id': userId.toString(),
              'fingerprint_token': fingerprintToken,
              'device_id': deviceId,
            },
          )
          .timeout(Duration(seconds: 30));

      print(
        'AuthService: Fingerprint login response status: ${res.statusCode}',
      );
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
        print(
          'AuthService: Fingerprint login failed - ${data['message'] ?? 'Unknown error'}',
        );
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
      // Get JWT token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        print('AuthService: No JWT token found in SharedPreferences');
        return false;
      }

      print('AuthService: Using JWT token for authentication');

      final res = await http
          .post(
            Uri.parse('$baseUrl/register_fingerprint.php'),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Authorization':
                  'Bearer $token', // Add JWT token in Authorization header
            },
            body: {
              'user_id': userId.toString(),
              'fingerprint_token': fingerprintToken,
              'device_id': deviceId,
              'token': token, // Also include token in body as fallback
            },
          )
          .timeout(Duration(seconds: 30));

      print(
        'AuthService: Fingerprint registration response status: ${res.statusCode}',
      );
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
        print(
          'AuthService: Fingerprint registration failed - ${data['message'] ?? 'Unknown error'}',
        );
      }

      return success;
    } on http.ClientException catch (e) {
      print('AuthService: Network error during fingerprint registration: $e');
      return false;
    } on FormatException catch (e) {
      print(
        'AuthService: JSON decode error during fingerprint registration: $e',
      );
      return false;
    } catch (e) {
      print(
        'AuthService: Unexpected error during fingerprint registration: $e',
      );
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getFingerprintData(
    String deviceId,
  ) async {
    print('AuthService: Getting fingerprint data for device: $deviceId');

    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/get_fingerprint_token.php'),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: {'device_id': deviceId},
          )
          .timeout(Duration(seconds: 30));

      print(
        'AuthService: Get fingerprint data response status: ${res.statusCode}',
      );
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
        print(
          'AuthService: Failed to get fingerprint data - ${data['message'] ?? 'Unknown error'}',
        );
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
      body: {'device_id': deviceId, 'user_id': userId.toString()},
    );

    final data = jsonDecode(res.body);
    if (data['success'] == true) {
      return data['fingerprint_token']; // Return the fingerprint token
    }
    return '';
  }

  static Future<File> _createTempFile(Uint8List data) async {
    final tempDir = await getTemporaryDirectory();
    final file = File(
      '${tempDir.path}/temp_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await file.writeAsBytes(data);
    return file;
  }

  static Future<Map<String, dynamic>> submitAttendance(
    String locationCode,
    String mode, {
    Uint8List? faceImage,
  }) async {
    print('Scanned location code: $locationCode');

    try {
      // Get JWT token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        print('No JWT token found in SharedPreferences');
        return {
          'success': false,
          'error': 'Not authenticated. Please log in again.',
        };
      }

      print(
        'JWT token retrieved from SharedPreferences: ${token.substring(0, 20)}...',
      );

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
          'error':
              'Location permission denied. Please allow location access in Settings.',
        };
      } else if (permission.isPermanentlyDenied) {
        return {
          'success': false,
          'error':
              'Location permission permanently denied. Please enable it in Settings.',
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
            'error':
                'Location services are disabled. Please enable location services.',
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
          'error': 'Failed to get location: ${e.toString()}',
        };
      }

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/submit_attendance.php'),
      );

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';

      // Add fields
      request.fields.addAll({
        'location_code': locationCode,
        'device_id': deviceId,
        'latitude': position.latitude.toString(),
        'longitude': position.longitude.toString(),
        'mode': mode,
        'token': token, // Add token to POST body as fallback
      });

      // Add face image if provided
      if (faceImage != null) {
        final file = await _createTempFile(faceImage);
        request.files.add(
          await http.MultipartFile.fromPath(
            'face_image',
            file.path,
            filename: 'face_${DateTime.now().millisecondsSinceEpoch}.jpg',
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }

      print('Sending attendance request with face image: ${faceImage != null}');

      // Send the request
      final streamedResponse = await request.send().timeout(
        Duration(seconds: 30),
      );
      final res = await http.Response.fromStream(streamedResponse);

      print('HTTP Status Code: ${res.statusCode}');
      print('API raw response: "${res.body}"');

      // Check HTTP status code
      if (res.statusCode != 200) {
        return {
          'success': false,
          'error': 'Server error: HTTP ${res.statusCode}',
        };
      }

      // Check if response is empty
      // ignore: unnecessary_null_comparison
      if (res.body == null || res.body.trim().isEmpty) {
        print('API returned empty response!');
        return {'success': false, 'error': 'Server returned empty response'};
      }

      // Try to decode JSON response
      try {
        final data = jsonDecode(res.body);
        print('API decoded response: $data');

        if (data['success'] == true) {
          return {'success': true};
        } else {
          // Server returned error message
          String errorMsg =
              data['message'] ?? data['error'] ?? 'Unknown server error';
          return {'success': false, 'error': errorMsg};
        }
      } catch (e) {
        print('Error decoding API response: $e');
        print('Raw response: "${res.body}"');
        return {
          'success': false,
          'error': 'Invalid response format from server',
        };
      }
    } catch (e) {
      print('Unexpected error in submitAttendance: $e');
      return {'success': false, 'error': 'Unexpected error: ${e.toString()}'};
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
        print(
          'getUserProfile: API returned success=false. Message: ${data['message']}',
        );
        return null;
      }
    } catch (e) {
      print('getUserProfile: Exception occurred: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> getTodayCheckinStatus() async {
    try {
      // Get the logged-in user ID
      final userId = await getUserId();
      if (userId == null) {
        return {
          'success': false,
          'message': 'User not logged in',
          'checked_in': false,
          'checked_out': false,
        };
      }

      // Get user profile to get the NIP (karyawan_id)
      final userProfile = await getUserProfile();
      if (userProfile == null || userProfile['nip'] == null) {
        return {
          'success': false,
          'message': 'User profile not found',
          'checked_in': false,
          'checked_out': false,
        };
      }

      final karyawanId = userProfile['nip'];

      final res = await http.post(
        Uri.parse('$baseUrl/get_today_checkin.php'),
        body: {'user_id': userId.toString(), 'karyawan_id': karyawanId},
      );

      if (res.statusCode != 200) {
        return {
          'success': false,
          'message': 'Failed to fetch check-in status',
          'checked_in': false,
          'checked_out': false,
        };
      }

      final data = json.decode(res.body);

      if (data['success'] == true) {
        return {
          'success': true,
          'checked_in': data['checked_in'] ?? false,
          'jam_in': data['jam_in'],
          'checked_out': data['checked_out'] ?? false,
          'jam_out': data['jam_out'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to get check-in status',
          'checked_in': false,
          'checked_out': false,
        };
      }
    } catch (e) {
      print('getTodayCheckinStatus error: $e');
      return {
        'success': false,
        'message': 'An error occurred',
        'checked_in': false,
        'checked_out': false,
      };
    }
  }

  // Updated getAttendanceHistory method for AuthService
  static Future<List<Map<String, dynamic>>> getAttendanceHistory(
    int userId,
    String startDate,
    String endDate,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/attendance_history.php'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'karyawan_id': userId.toString(),
          'start_date': startDate,
          'end_date': endDate,
        },
      );

      print('Attendance History Request:');
      print('URL: $baseUrl/attendance_history.php');
      print(
        'Body: karyawan_id=$userId, start_date=$startDate, end_date=$endDate',
      );
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
      final res = await http
          .post(
            Uri.parse('$baseUrl/get_user_devices.php'),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: {'user_id': userId.toString()},
          )
          .timeout(Duration(seconds: 30));

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

  static Future<List<Map<String, dynamic>>> getLatestAttendance(
    int userId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/attendance_latest.php'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'karyawan_id': userId.toString()},
      );

      if (response.statusCode != 200 || response.body.isEmpty) {
        return [];
      }

      final data = jsonDecode(response.body);
      if (data['success'] != true ||
          data['history'] == null ||
          data['history'] is! List) {
        return [];
      }

      return List<Map<String, dynamic>>.from(data['history']);
    } catch (e) {
      return [];
    }
  }

  /// Registers a user's face with the server
  ///
  /// [userId] The ID of the user to register the face for
  /// [faceImagePath] Path to the saved face image
  /// [faceEmbedding] JSON string containing the face embedding vector
  /// Returns true if registration was successful, false otherwise
  static Future<bool> registerFace({
    required int userId,
    required String faceImagePath,
    required String faceEmbedding,
  }) async {
    print('AuthService: Registering face for user: $userId');

    try {
      // Get JWT token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        print('AuthService: No JWT token found in SharedPreferences');
        return false;
      }

      // Check if image file exists
      var imageFile = File(faceImagePath);
      if (!await imageFile.exists()) {
        print('AuthService: Face image file not found at path: $faceImagePath');
        return false;
      }

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/register_faces.php'),
      );

      // Add headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      // Add fields
      request.fields['user_id'] = userId.toString();
      request.fields['face_embedding'] = faceEmbedding;

      // Add image file
      try {
        var multipartFile = await http.MultipartFile.fromPath(
          'face_image',
          faceImagePath,
          filename: 'face_${DateTime.now().millisecondsSinceEpoch}.jpg',
          contentType: MediaType('image', 'jpeg'),
        );
        request.files.add(multipartFile);
      } catch (e) {
        print('AuthService: Error adding file to request: $e');
        return false;
      }

      print('AuthService: Sending face registration request...');

      // Send request with timeout
      var streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException(
            'Request timeout',
            const Duration(seconds: 30),
          );
        },
      );

      var response = await http.Response.fromStream(streamedResponse);

      print(
        'AuthService: Face registration response status: ${response.statusCode}',
      );
      print(
        'AuthService: Face registration response headers: ${response.headers}',
      );
      print('AuthService: Face registration response body: ${response.body}');

      // Check if response is HTML (error page)
      if (response.body.trim().startsWith('<') ||
          response.body.contains('<br')) {
        print('AuthService: Server returned HTML error page instead of JSON');
        return false;
      }

      if (response.statusCode != 200) {
        print(
          'AuthService: HTTP error during face registration: ${response.statusCode}',
        );
        return false;
      }

      if (response.body.isEmpty) {
        print('AuthService: Empty response body from face registration');
        return false;
      }

      // Parse JSON response
      late Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body);
      } catch (e) {
        print('AuthService: Failed to parse JSON response: $e');
        print('AuthService: Raw response: ${response.body}');
        return false;
      }

      bool success = data['success'] == true;

      if (success) {
        print('AuthService: Face registration successful');
        if (data.containsKey('face_id')) {
          print('AuthService: Face ID: ${data['face_id']}');
        }
      } else {
        print(
          'AuthService: Face registration failed - ${data['message'] ?? 'Unknown error'}',
        );
        if (data.containsKey('errors')) {
          print('AuthService: Validation errors: ${data['errors']}');
        }
      }

      return success;
    } on TimeoutException catch (e) {
      print('AuthService: Request timeout during face registration: $e');
      return false;
    } on http.ClientException catch (e) {
      print('AuthService: Network error during face registration: $e');
      return false;
    } on FormatException catch (e) {
      print('AuthService: JSON decode error during face registration: $e');
      return false;
    } catch (e) {
      print('AuthService: Unexpected error during face registration: $e');
      return false;
    }
  }

  /// Checks if a user has registered their face
  ///
  /// [userId] The ID of the user to check
  /// Returns true if the user has a registered face, false otherwise
  static Future<bool> hasRegisteredFace(int userId) async {
    print('AuthService: Checking if user $userId has registered face');

    try {
      // Get JWT token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        print('AuthService: No JWT token found in SharedPreferences');
        return false;
      }

      print('AuthService: Retrieved token from SharedPreferences');
      print(
        'AuthService: Token: ${token.substring(0, 20)}...',
      ); // Log first 20 chars of token

      // Create the URL with query parameters
      final uri = Uri.parse(
        '$baseUrl/check_face_registration.php',
      ).replace(queryParameters: {'user_id': userId.toString()});

      print('AuthService: Sending request to: ${uri.toString()}');

      // Make the GET request with proper headers
      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

      print('AuthService: Request headers: $headers');

      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));

      print('AuthService: Response status: ${response.statusCode}');
      print('AuthService: Response headers: ${response.headers}');
      print('AuthService: Response body: ${response.body}');

      if (response.statusCode != 200) {
        print('AuthService: HTTP error - Status code: ${response.statusCode}');
        return false;
      }

      if (response.body.isEmpty) {
        print('AuthService: Empty response body');
        return false;
      }

      try {
        final data = jsonDecode(response.body);
        if (data is! Map<String, dynamic>) {
          print('AuthService: Invalid response format - expected JSON object');
          return false;
        }

        if (data['success'] != true) {
          print(
            'AuthService: API returned error: ${data['message'] ?? 'Unknown error'}',
          );
          return false;
        }

        return data['has_face'] == true;
      } catch (e) {
        print('AuthService: Error parsing response: $e');
        return false;
      }
    } on TimeoutException catch (e) {
      print('AuthService: Timeout checking face registration: $e');
      return false;
    } on http.ClientException catch (e) {
      print('AuthService: Network error checking face registration: $e');
      return false;
    } catch (e) {
      print('AuthService: Error checking face registration: $e');
      return false;
    }
  }

  static Future<String?> getUserFaceEmbedding(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/get_faces_embedding.php?user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['face_embedding'];
        }
      }
      return null;
    } catch (e) {
      print('Error fetching face embedding: $e');
      return null;
    }
  }
}
