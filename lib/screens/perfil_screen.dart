import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'admin_screen.dart';
import 'auth_screen.dart';
import 'metrics_screen.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});
  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  String _rol = 'USUARIO';
  String _nombre = '';
  String _correo = '';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final rol = await StorageService.getRol() ?? 'USUARIO';
    final nombre = await StorageService.getNombre() ?? '';
    final correo = await StorageService.getCorreo() ?? '';
    setState(() {
      _rol = rol;
      _nombre = nombre;
      _correo = correo;
    });
  }

  Future<void> _cerrarSesion() async {
    await StorageService.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (_) => false,
    );
  }

  String get _iniciales {
    final partes = _nombre.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (partes.isEmpty) return '?';
    return partes.take(2).map((p) => p[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final esAdmin = _rol == 'ADMIN';
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Mi perfil',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primary,
                    child: Text(_iniciales,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_nombre.isEmpty ? 'Usuario' : _nombre,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 16)),
                        const SizedBox(height: 2),
                        Text(_correo,
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 13)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(esAdmin ? 'Administrador' : 'Usuario civil',
                              style: const TextStyle(
                                  color: AppColors.primaryLight,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (esAdmin) ...[
              const SizedBox(height: 24),
              const Text('ADMINISTRACIÓN',
                  style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6)),
              const SizedBox(height: 10),
              _opcion(
                icon: Icons.admin_panel_settings_outlined,
                color: AppColors.primaryLight,
                label: 'Panel administrativo',
                onTap: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const AdminScreen())),
              ),
              const SizedBox(height: 10),
              _opcion(
                icon: Icons.bar_chart_rounded,
                color: AppColors.purple,
                label: 'Panel de métricas',
                onTap: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const MetricsScreen())),
              ),
            ],
            const SizedBox(height: 24),
            const Text('CUENTA',
                style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6)),
            const SizedBox(height: 10),
            _opcion(
              icon: Icons.logout,
              color: AppColors.danger,
              label: 'Cerrar sesión',
              onTap: _cerrarSesion,
            ),
          ],
        ),
      ),
    );
  }

  Widget _opcion({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 14),
            Expanded(
                child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
