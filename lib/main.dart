import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart' as firebase_core;
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'services/firebase_service.dart' as app_firebase;
import 'services/sesion_service.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await firebase_core.Firebase.initializeApp();
  } catch (_) {
    // Sin Firebase la app sigue funcionando, solo sin notificaciones push.
  }
  runApp(const AppMonitoreo());
}

class AppMonitoreo extends StatelessWidget {
  const AppMonitoreo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AlertaZona',
      debugShowCheckedModeBanner: false,
      navigatorKey: SesionService.navigatorKey,
      scaffoldMessengerKey: SesionService.messengerKey,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: const SplashRouter(),
    );
  }
}

class SplashRouter extends StatefulWidget {
  const SplashRouter({super.key});
  @override
  State<SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<SplashRouter> {
  @override
  void initState() {
    super.initState();
    _redirigir();
  }

  Future<void> _redirigir() async {
    final vigente = await SesionService.tokenVigente();
    if (vigente) {
      // No se espera: el permiso de notificaciones no debe frenar el arranque.
      app_firebase.FirebaseService.init();
    } else {
      await StorageService.clear();
    }
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => vigente ? const HomeScreen() : const AuthScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
