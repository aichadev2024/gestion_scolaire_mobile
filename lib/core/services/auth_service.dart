import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import '../constants/api_constants.dart';

class AuthService {
  static const String _keyToken = 'jwt_token';
  static const String _keyUserData = 'user_data';

  static Future<Map<String, dynamic>?> login(String username, String password) async {
    try {
      final data = await ApiService.post(ApiConstants.login, {
        'identifiant': username,
        'username': username,
        'motDePasse': password,
      });

      if (data != null && data['token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyToken, data['token']);
        await prefs.setString(_keyUserData, jsonEncode(data));
      }
      return data;
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> verifyOtp(int utilisateurId, String otpCode) async {
    try {
      final data = await ApiService.post(ApiConstants.verifyOtp, {
        'utilisateurId': utilisateurId,
        'otpCode': otpCode,
      });

      if (data != null && data['token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyToken, data['token']);
        await prefs.setString(_keyUserData, jsonEncode(data));
      }
      return data;
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> resendOtp(int utilisateurId) async {
    try {
      final data = await ApiService.post(ApiConstants.resendOtp, {
        'utilisateurId': utilisateurId,
      });
      return data;
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUserData);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyUserData);
    if (jsonStr != null) {
      return jsonDecode(jsonStr);
    }
    return null;
  }

  static Future<String> getRole() async {
    final user = await getUserData();
    return user?['role'] ?? 'ELEVE';
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
