import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8080';

  static Map<String, String> _headers(String? token) {
    final h = {'Content-Type': 'application/json'};
    if (token != null) h['Authorization'] = 'Bearer $token';
    return h;
  }

  static Future<http.Response> post(String path, Map<String, dynamic> body,
      {String? token}) async {
    return http.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers(token),
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> get(String path,
      {String? token, Map<String, String>? queryParams}) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: queryParams);
    return http.get(uri, headers: _headers(token));
  }

  static Future<http.Response> put(String path, Map<String, dynamic> body,
      {String? token}) async {
    return http.put(
      Uri.parse('$baseUrl$path'),
      headers: _headers(token),
      body: jsonEncode(body),
    );
  }
}
