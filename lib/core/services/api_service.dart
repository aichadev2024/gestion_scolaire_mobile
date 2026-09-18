import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import 'auth_service.dart';

/// Messages d'erreur compréhensibles par un utilisateur non technique — jamais
/// une exception brute (SocketException, FormatException, code HTTP nu...).
class ApiService {
  static String get baseUrl => ApiConstants.productionUrl;

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

  /// Le backend (Render, offre gratuite) se met en veille après inactivité et peut
  /// prendre 30 à 50s à se réveiller sur la toute première requête — un timeout de 10s
  /// déclenchait alors une fausse alerte "pas de connexion" alors que le téléphone était
  /// bien connecté. On laisse large et on retente une fois avant d'abandonner.
  static const Duration _timeout = Duration(seconds: 30);

  static Future<dynamic> get(String endpoint) => _appel(
        () async => http.get(Uri.parse('$baseUrl$endpoint'), headers: await _getHeaders()).timeout(_timeout),
      );

  /// Télécharge un fichier binaire (ex. PDF d'un reçu) avec le jeton de l'utilisateur.
  static Future<List<int>> getBytes(String endpoint) async {
    try {
      final headers = await _getHeaders();
      headers['Accept'] = '*/*';
      final response = await http.get(Uri.parse('$baseUrl$endpoint'), headers: headers).timeout(_timeout);
      if (response.statusCode >= 200 && response.statusCode < 300) return response.bodyBytes;
      if (response.statusCode == 401) throw Exception('Votre session a expiré. Reconnectez-vous.');
      if (response.statusCode == 403) throw Exception("Vous n'avez pas la permission d'ouvrir ce document.");
      if (response.statusCode == 404) throw Exception('Document introuvable.');
      throw Exception('Le document est momentanément indisponible. Réessayez dans un instant.');
    } on TimeoutException {
      throw Exception('Le serveur met trop de temps à répondre. Réessayez dans un instant.');
    } on SocketException {
      throw Exception('Impossible de joindre le serveur. Vérifiez votre connexion et réessayez.');
    }
  }

  static Future<dynamic> post(String endpoint, Map<String, dynamic> body) => _appel(
        () async => http
            .post(Uri.parse('$baseUrl$endpoint'), headers: await _getHeaders(), body: jsonEncode(body))
            .timeout(_timeout),
      );

  static Future<dynamic> put(String endpoint, Map<String, dynamic> body) => _appel(
        () async => http
            .put(Uri.parse('$baseUrl$endpoint'), headers: await _getHeaders(), body: jsonEncode(body))
            .timeout(_timeout),
      );

  static Future<dynamic> patch(String endpoint, [Map<String, dynamic>? body]) => _appel(
        () async => http
            .patch(Uri.parse('$baseUrl$endpoint'), headers: await _getHeaders(), body: body != null ? jsonEncode(body) : null)
            .timeout(_timeout),
      );

  /// Exécute la requête et transforme toute erreur réseau/serveur bas niveau
  /// en message compréhensible — un parent ou une monitrice ne doit jamais
  /// voir "SocketException" ou "FormatException" s'afficher à l'écran. Une seule
  /// retentative silencieuse avant d'abandonner : beaucoup d'échecs réseau sur
  /// mobile (bascule Wi-Fi/données, DNS lent) sont transitoires.
  static Future<dynamic> _appel(Future<http.Response> Function() requete) async {
    try {
      final response = await requete();
      return _handleResponse(response);
    } on TimeoutException {
      throw Exception('Le serveur met trop de temps à répondre. Réessayez dans un instant.');
    } on SocketException {
      try {
        final response = await requete();
        return _handleResponse(response);
      } on TimeoutException {
        throw Exception('Le serveur met trop de temps à répondre. Réessayez dans un instant.');
      } on SocketException {
        throw Exception(
            "Impossible de joindre le serveur. Vérifiez votre connexion Wi-Fi ou vos données mobiles, ou réessayez dans un instant.");
      } on HttpException {
        throw Exception('Impossible de joindre le serveur. Réessayez dans un instant.');
      } on FormatException {
        throw Exception('Réponse du serveur illisible. Réessayez, et contactez le support si ça persiste.');
      }
    } on HttpException {
      throw Exception('Impossible de joindre le serveur. Réessayez dans un instant.');
    } on FormatException {
      throw Exception('Réponse du serveur illisible. Réessayez, et contactez le support si ça persiste.');
    }
  }

  static dynamic _handleResponse(http.Response response) {
    final code = response.statusCode;
    if (code >= 200 && code < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }

    // Le backend fournit presque toujours un message clair en français — on le
    // préfère toujours à notre texte générique quand il est présent.
    String? messageServeur;
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['message'] is String && (body['message'] as String).trim().isNotEmpty) {
        messageServeur = body['message'];
      }
    } catch (_) {
      // corps non-JSON (page d'erreur brute d'un proxy, etc.) : on retombe sur le message générique
    }

    if (messageServeur != null) throw Exception(messageServeur);

    final String message = switch (code) {
      400 => 'Requête invalide. Vérifiez les informations saisies.',
      401 => 'Votre session a expiré. Reconnectez-vous.',
      403 => 'Vous n\'avez pas la permission d\'effectuer cette action.',
      404 => 'Élément introuvable.',
      >= 500 => 'Le serveur est momentanément indisponible. Réessayez dans un instant.',
      _ => 'Une erreur est survenue (code $code). Réessayez.',
    };
    throw Exception(message);
  }
}
