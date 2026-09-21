import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart' as firebase_core;
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'services/firebase_service.dart' as app_firebase;
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await firebase_core.Firebase.initializeApp();
  runApp(const AppMonitoreo());
}

class AppMonitoreo extends StatelessWidget {
  const AppMonitoreo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AlertaZona',
      debugShowCheckedModeBanner: false,
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
    final token = await StorageService.getToken();
    if (token != null) {
      await app_firebase.FirebaseService.init();
    }
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            token != null ? const HomeScreen() : const AuthScreen(),
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
