import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'sesion_service.dart';

class ApiService {
  // Se puede cambiar sin tocar el código:
  //   flutter run --dart-define=API_URL=http://192.168.1.50:8080
  // 10.0.2.2 es el "localhost" de la PC visto desde el emulador de Android.
  static const String baseUrl =
      String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:8080');

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
    final res = await http
        .post(
          Uri.parse('$baseUrl$path'),
          headers: _headers(token),
          body: jsonEncode(body),
        )
        .timeout(_timeout);
    return _revisarSesion(path, res);
  }

  static Future<http.Response> get(String path,
      {String? token, Map<String, String>? queryParams}) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: queryParams);
    final res = await http.get(uri, headers: _headers(token)).timeout(_timeout);
    return _revisarSesion(path, res);
  }

  static Future<http.Response> put(String path, Map<String, dynamic> body,
      {String? token}) async {
    final res = await http
        .put(
          Uri.parse('$baseUrl$path'),
          headers: _headers(token),
          body: jsonEncode(body),
        )
        .timeout(_timeout);
    return _revisarSesion(path, res);
  }

  // Un 401 fuera de /auth significa que el JWT venció o es inválido.
  static http.Response _revisarSesion(String path, http.Response res) {
    if (res.statusCode == 401 && !path.startsWith('/auth')) {
      SesionService.cerrar(mensaje: 'Tu sesión expiró. Inicia sesión de nuevo.');
    }
    return res;
  }

  // El backend responde "application/json" sin charset y http asume latin1,
  // lo que rompe tildes y eñes; por eso se decodifica siempre como UTF-8.
  static dynamic decodificar(http.Response res) =>
      jsonDecode(utf8.decode(res.bodyBytes));

  /// Mensaje legible a partir de una respuesta de error del backend
  /// ({"error": "...", "detalles": {"campo": "mensaje"}}).
  static String mensajeError(http.Response res,
      {String porDefecto = 'Ocurrió un error. Intenta de nuevo.'}) {
    try {
      final body = decodificar(res);
      if (body is Map) {
        final detalles = body['detalles'];
        if (detalles is Map && detalles.isNotEmpty) {
          return detalles.values.first.toString();
        }
        final msg = body['mensaje'] ?? body['error'];
        if (msg is String && msg.isNotEmpty) return msg;
      }
    } catch (_) {}
    return porDefecto;
  }

  /// Mensaje legible para excepciones de red.
  static String mensajeExcepcion(Object e) {
    if (e is TimeoutException) {
      return 'El servidor no responde. Intenta de nuevo en unos segundos.';
    }
    if (e is SocketException || e is http.ClientException) {
      return 'No hay conexión con el servidor. Revisa tu internet.';
    }
    return 'Ocurrió un error inesperado. Intenta de nuevo.';
  }
}
