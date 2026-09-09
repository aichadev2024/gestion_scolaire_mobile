import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import '../constants/api_constants.dart';

class AuthService {
  static const String _keyToken = 'jwt_token';
  static const String _keyUserData = 'user_data';

  /// Stockage chiffré (Keychain iOS / EncryptedSharedPreferences Android /
  /// WebCrypto sur le web) pour les données d'authentification sensibles.
  static const FlutterSecureStorage _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static Future<void> _persistSession(Map<String, dynamic> data) async {
    await _secure.write(key: _keyToken, value: data['token'] as String);
    await _secure.write(key: _keyUserData, value: jsonEncode(data));
  }

  static Future<Map<String, dynamic>?> login(String username, String password) async {
    try {
      final data = await ApiService.post(ApiConstants.login, {
        'identifiant': username,
        'username': username,
        'motDePasse': password,
      });

      if (data != null && data['token'] != null) {
        await _persistSession(data);
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
        await _persistSession(data);
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
    await _secure.delete(key: _keyToken);
    await _secure.delete(key: _keyUserData);
    // Nettoyage défensif d'une éventuelle session héritée en clair.
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUserData);
  }

  /// Migration ponctuelle : si une session existe encore en clair dans
  /// SharedPreferences (anciennes versions), on la déplace vers le stockage
  /// chiffré et on efface la copie en clair.
  static Future<String?> _migrateLegacyIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final legacyToken = prefs.getString(_keyToken);
    if (legacyToken == null || legacyToken.isEmpty) return null;

    await _secure.write(key: _keyToken, value: legacyToken);
    final legacyUser = prefs.getString(_keyUserData);
    if (legacyUser != null) {
      await _secure.write(key: _keyUserData, value: legacyUser);
    }
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUserData);
    return legacyToken;
  }

  static Future<String?> getToken() async {
    final token = await _secure.read(key: _keyToken);
    if (token != null && token.isNotEmpty) return token;
    return _migrateLegacyIfNeeded();
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    var jsonStr = await _secure.read(key: _keyUserData);
    if (jsonStr == null) {
      // Peut avoir été déplacée par la migration déclenchée dans getToken().
      await _migrateLegacyIfNeeded();
      jsonStr = await _secure.read(key: _keyUserData);
    }
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
