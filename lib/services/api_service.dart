import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8080';

  // RNF01: el backend debe responder en <3s en condiciones normales; este
  // timeout es solo una red de seguridad para no dejar la UI colgada si el
  // servidor no responde en absoluto.
  static const _timeout = Duration(seconds: 10);

  static Map<String, String> _headers(String? token) {
    final h = {'Content-Type': 'application/json'};
    if (token != null) h['Authorization'] = 'Bearer $token';
    return h;
  }

  static Future<http.Response> post(String path, Map<String, dynamic> body,
      {String? token}) async {
    return http
        .post(
          Uri.parse('$baseUrl$path'),
          headers: _headers(token),
          body: jsonEncode(body),
        )
        .timeout(_timeout);
  }

  static Future<http.Response> get(String path,
      {String? token, Map<String, String>? queryParams}) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: queryParams);
    return http.get(uri, headers: _headers(token)).timeout(_timeout);
  }

  static Future<http.Response> put(String path, Map<String, dynamic> body,
      {String? token}) async {
    return http
        .put(
          Uri.parse('$baseUrl$path'),
          headers: _headers(token),
          body: jsonEncode(body),
        )
        .timeout(_timeout);
  }
}
