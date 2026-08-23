import 'package:firebase_messaging/firebase_messaging.dart';
import 'api_service.dart';
import 'storage_service.dart';

class FirebaseService {
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    try {
      final messaging = FirebaseMessaging.instance;

      await messaging.requestPermission(alert: true, badge: true, sound: true);

      final token = await messaging.getToken();
      if (token != null) {
        await _enviarTokenAlBackend(token);
      }

      FirebaseMessaging.instance.onTokenRefresh.listen(_enviarTokenAlBackend);
      _initialized = true;
    } catch (_) {}
  }

  static Future<void> _enviarTokenAlBackend(String fcmToken) async {
    try {
      final jwt = await StorageService.getToken();
      if (jwt == null) return;
      await ApiService.put('/usuarios/token-fcm', {'tokenFcm': fcmToken},
          token: jwt);
    } catch (_) {}
  }
}
