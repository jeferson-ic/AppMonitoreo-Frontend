import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const _storage = FlutterSecureStorage();
  static const _keyToken = 'jwt_token';
  static const _keyRol = 'user_rol';
  static const _keyCorreo = 'user_correo';
  static const _keyNombre = 'user_nombre';

  static Future<void> saveSession(
      {required String token,
      required String correo,
      required String nombre,
      required String rol}) async {
    await _storage.write(key: _keyToken, value: token);
    await _storage.write(key: _keyCorreo, value: correo);
    await _storage.write(key: _keyNombre, value: nombre);
    await _storage.write(key: _keyRol, value: rol);
  }

  static Future<String?> getToken() => _storage.read(key: _keyToken);
  static Future<String?> getRol() => _storage.read(key: _keyRol);
  static Future<String?> getCorreo() => _storage.read(key: _keyCorreo);
  static Future<String?> getNombre() => _storage.read(key: _keyNombre);

  static Future<void> clear() => _storage.deleteAll();
}
