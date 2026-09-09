import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import 'auth_service.dart';

class ApiService {
  static const String _keyCustomIp = 'custom_server_ip';

  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final customIp = prefs.getString(_keyCustomIp);
    if (customIp != null && customIp.trim().isNotEmpty) {
      final ip = customIp.trim();
      if (ip.startsWith('http')) return ip.endsWith('/api') ? ip : '$ip/api';
      return 'http://$ip:8089/api';
    }
    return ApiConstants.productionUrl;
  }

  static Future<void> saveCustomIp(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCustomIp, ip.trim());
  }

  static Future<String?> getCustomIp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCustomIp);
  }

  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<dynamic> get(String endpoint) async {
    final headers = await _getHeaders();
    final baseUrl = await getBaseUrl();
    final url = Uri.parse('$baseUrl$endpoint');
    final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 10));
    return _handleResponse(response);
  }

  static Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final baseUrl = await getBaseUrl();
    final url = Uri.parse('$baseUrl$endpoint');
    final response = await http.post(url, headers: headers, body: jsonEncode(body)).timeout(const Duration(seconds: 10));
    return _handleResponse(response);
  }

  static Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final baseUrl = await getBaseUrl();
    final url = Uri.parse('$baseUrl$endpoint');
    final response = await http.put(url, headers: headers, body: jsonEncode(body)).timeout(const Duration(seconds: 10));
    return _handleResponse(response);
  }

  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      String message = 'Erreur serveur (${response.statusCode})';
      try {
        final body = jsonDecode(response.body);
        if (body is Map && body.containsKey('message')) {
          message = body['message'];
        }
      } catch (_) {}
      throw Exception(message);
    }
  }
}
