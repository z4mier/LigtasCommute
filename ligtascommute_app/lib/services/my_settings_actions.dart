// lib/services/my_settings_actions.dart
import 'dart:convert';
import 'dart:io';
import 'dart:async'; // <-- for TimeoutException
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/settings_screen.dart';
import '../api_config.dart';

class MySettingsActions implements SettingsActions {
  bool _dark = false;
  String _lang = 'en';

  // ----- getters -----
  @override
  bool get isDarkMode => _dark;
  @override
  String get languageCode => _lang;

  // ----- prefs helpers -----
  Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();
  Future<String?> _getToken() async => (await _prefs()).getString('auth_token');

  Map<String, String> _headers(String token) => {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Uri _u(String path) => Uri.parse('${ApiConfig.baseUrl}$path'); // baseUrl must end with /api/

  // ----- API: Get current user -----
  @override
  Future<AppUser> loadMe() async {
    final token = await _getToken();
    if (token == null) throw Exception('No auth token found. Please log in again.');

    http.Response res;
    try {
      res = await http
          .get(_u('user'), headers: _headers(token))
          .timeout(const Duration(seconds: 15));
    } on SocketException {
      throw Exception('Network error. Please check your connection.');
    } on TimeoutException {
      throw Exception('Request timed out. Please try again.');
    }

    if (res.statusCode == 401) {
      final p = await _prefs();
      await p.remove('auth_token');
      throw Exception('Session expired. Please log in again.');
    }
    if (res.statusCode != 200) {
      throw Exception('Failed to fetch profile (${res.statusCode}): ${res.body}');
    }

    final body = jsonDecode(res.body);
    final map = (body is Map && body['user'] is Map) ? body['user'] : body;
    if (map is! Map) throw Exception('Unexpected profile payload.');

    return AppUser.fromJson(Map<String, dynamic>.from(map));
  }

  // ----- API: Update profile -----
  @override
  Future<AppUser> updateProfile({
    required String fullName,
    required String email,
    String? phone,
    String? location,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('No auth token found.');

    final res = await http
        .patch(
          _u('user'),
          headers: {
            ..._headers(token),
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'name': fullName,
            'email': email,
            'phone': phone,
            'location': location,
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (res.statusCode == 401) throw Exception('Session expired. Please log in again.');
    if (res.statusCode != 200) {
      throw Exception('Update failed (${res.statusCode}): ${res.body}');
    }

    final map = jsonDecode(res.body);
    return AppUser.fromJson(Map<String, dynamic>.from(map));
  }

  // ----- API: Update username -----
  @override
  Future<void> updateUsername({
    required String currentUsername,
    required String newUsername,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('No auth token found.');

    final res = await http
        .post(
          _u('user/username'),
          headers: {
            ..._headers(token),
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'current_username': currentUsername,
            'new_username': newUsername,
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (res.statusCode == 401) throw Exception('Session expired. Please log in again.');
    if (res.statusCode != 200) {
      throw Exception('Username update failed (${res.statusCode}): ${res.body}');
    }
  }

  // ----- API: Update password -----
  @override
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('No auth token found.');

    final res = await http
        .post(
          _u('user/password'),
          headers: {
            ..._headers(token),
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'current_password': currentPassword,
            'new_password': newPassword,
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (res.statusCode == 401) throw Exception('Session expired. Please log in again.');
    if (res.statusCode != 200) {
      throw Exception('Password update failed (${res.statusCode}): ${res.body}');
    }
  }

  // ----- local prefs -----
  @override
  Future<void> changeLanguage(String code) async {
    _lang = code;
    final p = await _prefs();
    await p.setString('language', code);
  }

  @override
  Future<void> toggleDarkMode(bool enabled) async {
    _dark = enabled;
    final p = await _prefs();
    await p.setBool('dark_mode', enabled);
  }

  // ----- Non-critical mock endpoints -----
  @override
  Future<void> redeemRewards() async {
    final token = await _getToken();
    if (token == null) return;
    try {
      await http
          .post(_u('rewards/redeem'), headers: _headers(token))
          .timeout(const Duration(seconds: 10));
    } catch (_) {/* ignore */}
  }

  @override
  Future<void> openTerms() async {}
  @override
  Future<void> openHelp() async {}

  // ----- Logout -----
  @override
  Future<void> logout() async {
    final token = await _getToken();
    if (token != null) {
      try {
        await http
            .post(_u('logout'), headers: _headers(token))
            .timeout(const Duration(seconds: 10));
      } catch (_) {/* ignore */}
    }
    final p = await _prefs();
    await p.remove('auth_token');
  }
}
