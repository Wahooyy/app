import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';


class AuthService {
  // static const String baseUrl = 'http://kahap.42web.io/auth_app_api';
  // static const String baseUrl = 'http://103.76.15.27/auth_app_api';
  static const String baseUrl = 'http://192.168.4.152/erp/attendance_api';
  // static const String baseUrl = 'http://192.168.4.25/auth_app_api';
  // static const String baseUrl = 'http://192.168.1.229/auth_app_api';
  // static const String baseUrl = 'http://10.0.2.2/auth_app_api';

  static Future<bool> login(String username, String password) async {
  final res = await http.post(
    Uri.parse('$baseUrl/login.php'),
    body: {'username': username, 'password': password},
  );

  print('RESPONSE STATUS: ${res.statusCode}');
  print('RESPONSE BODY: ${res.body}');

  try {
    final data = jsonDecode(res.body);
    return data['success'] == true;
  } catch (e) {
    print('JSON decode error: $e');
    return false;
  }
}


  // Function to handle fingerprint login
  static Future<bool> fingerprintLogin({
    required String fingerprintToken,
    required String deviceId,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/fingerprint_login.php'),
      body: {
        'fingerprint_token': fingerprintToken,
        'device_id': deviceId,
      },
    );

    final data = jsonDecode(res.body);
    return data['success'] == true;
  }



  static Future<bool> registerWithFingerprint(
    String name,
    String username,
    String password,
    String fingerprintToken,
    String deviceId, // Menambahkan deviceId sebagai parameter
  ) async {
    // Step 1: Register user
    final res = await http.post(
      Uri.parse('$baseUrl/register.php'),
      body: {
        'name': name,
        'username': username,
        'password': password,
      },
    );

    print('RESPONSE STATUS: ${res.statusCode}');
    print('RESPONSE BODY: ${res.body}');

    final data = jsonDecode(res.body);
    if (data['success'] != true) {
      return false;
    }

    final userId = data['user_id'];

    // Step 2: Register fingerprint
    final fingerprintRes = await http.post(
      Uri.parse('$baseUrl/register_fingerprint.php'),
      body: {
        'user_id': userId.toString(),
        'fingerprint_token': fingerprintToken,
        'device_id': deviceId,  // Menggunakan deviceId yang dikirim dari SignUpPage
      },
    );

    print('RESPONSE STATUS: ${res.statusCode}');
    print('RESPONSE BODY: ${res.body}');

    final fpData = jsonDecode(fingerprintRes.body);
    return fpData['success'] == true;
  }


  // Function to get the fingerprint token from the database based on device ID
  static Future<String> getFingerprintToken(String deviceId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/get_fingerprint_token.php'),
      body: {'device_id': deviceId},
    );

    final data = jsonDecode(res.body);
    if (data['success'] == true) {
      return data['fingerprint_token']; // Return the fingerprint token
    }
    return '';
  }

  static Future<bool> submitAttendance(String locationCode) async {
    final deviceInfo = DeviceInfoPlugin();
    String deviceId = '';

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      deviceId = androidInfo.id ?? 'unknown';
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

    final res = await http.post(
      Uri.parse('$baseUrl/submit_attendance.php'),
      body: {
        'location_code': locationCode,
        'device_id': deviceId,
        'latitude': position.latitude.toString(),
        'longitude': position.longitude.toString(),
      },
    );

    final data = jsonDecode(res.body);
    return data['success'] == true;
  }
}
