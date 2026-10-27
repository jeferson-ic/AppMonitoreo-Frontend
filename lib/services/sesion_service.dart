import 'dart:convert';
import 'package:flutter/material.dart';
import '../screens/auth_screen.dart';
import 'firebase_service.dart';
import 'storage_service.dart';

class SesionService {
  static final navigatorKey = GlobalKey<NavigatorState>();
  static final messengerKey = GlobalKey<ScaffoldMessengerState>();

  static bool _cerrando = false;

  /// true si hay un token guardado y no ha vencido según su campo "exp".
  static Future<bool> tokenVigente() async {
    final token = await StorageService.getToken();
    if (token == null) return false;
    try {
      final partes = token.split('.');
      if (partes.length != 3) return false;
      final payload = jsonDecode(
          utf8.decode(base64Url.decode(base64Url.normalize(partes[1]))));
      final exp = payload['exp'];
      if (exp is! num) return true;
      final vence = DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000);
      return DateTime.now().isBefore(vence);
    } catch (_) {
      return false;
    }
  }

  /// Borra la sesión local, deja de recibir push y vuelve al login.
  static Future<void> cerrar({String? mensaje}) async {
    // Varias peticiones pueden recibir 401 a la vez; solo se cierra una vez.
    if (_cerrando) return;
    _cerrando = true;
    try {
      await FirebaseService.reset();
      await StorageService.clear();
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (_) => false,
      );
      if (mensaje != null) {
        messengerKey.currentState?.showSnackBar(SnackBar(content: Text(mensaje)));
      }
    } finally {
      _cerrando = false;
    }
  }
}
