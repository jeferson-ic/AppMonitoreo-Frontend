import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/firebase_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/labeled_field.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _esLogin = true;

  final _formKeyLogin = GlobalKey<FormState>();
  final _formKeyRegistro = GlobalKey<FormState>();

  final _correoCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _correoRegCtrl = TextEditingController();
  final _passRegCtrl = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _correoCtrl.dispose();
    _passCtrl.dispose();
    _nombreCtrl.dispose();
    _correoRegCtrl.dispose();
    _passRegCtrl.dispose();
    super.dispose();
  }

  void _mostrarMensaje(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _login() async {
    if (!_formKeyLogin.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final res = await ApiService.post('/auth/login', {
        'correo': _correoCtrl.text.trim(),
        'contrasena': _passCtrl.text,
      });
      if (!mounted) return;
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        await StorageService.saveSession(
          token: data['token'],
          correo: data['correo'],
          nombre: data['nombre'],
          rol: data['rol'],
        );
        await FirebaseService.init();
        if (!mounted) return;
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      } else {
        _mostrarMensaje('Credenciales incorrectas');
      }
    } catch (e) {
      _mostrarMensaje('Error de conexión: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _registrar() async {
    if (!_formKeyRegistro.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final res = await ApiService.post('/auth/register', {
        'nombre': _nombreCtrl.text.trim(),
        'correo': _correoRegCtrl.text.trim(),
        'contrasena': _passRegCtrl.text,
      });
      if (!mounted) return;
      if (res.statusCode == 201) {
        _mostrarMensaje('Registro exitoso. Inicia sesión.');
        setState(() {
          _esLogin = true;
          _correoCtrl.text = _correoRegCtrl.text.trim();
        });
      } else {
        final body = jsonDecode(res.body);
        _mostrarMensaje(body['mensaje'] ?? body['error'] ?? 'Error en el registro');
      }
    } catch (e) {
      _mostrarMensaje('Error de conexión: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            children: [
              _Encabezado(),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _Segmentado(
                      esLogin: _esLogin,
                      onChanged: (v) => setState(() => _esLogin = v),
                    ),
                    const SizedBox(height: 20),
                    if (_esLogin) _formLogin() else _formRegistro(),
                    const SizedBox(height: 20),
                    Row(children: const [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('o continúa con',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      ),
                      Expanded(child: Divider()),
                    ]),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () =>
                          _mostrarMensaje('Inicio con Google próximamente disponible'),
                      icon: const Text('G',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, color: Color(0xFF4285F4))),
                      label: const Text('Continuar con Google'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              RichText(
                textAlign: TextAlign.center,
                text: const TextSpan(
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  children: [
                    TextSpan(text: 'Al continuar aceptas los '),
                    TextSpan(
                      text: 'Términos de servicio',
                      style: TextStyle(
                          color: AppColors.primaryLight, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _formLogin() {
    return Form(
      key: _formKeyLogin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LabeledField(
            label: 'Correo electrónico',
            child: TextFormField(
              controller: _correoCtrl,
              decoration: const InputDecoration(hintText: 'correo@ejemplo.com'),
              keyboardType: TextInputType.emailAddress,
              validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
            ),
          ),
          const SizedBox(height: 14),
          LabeledField(
            label: 'Contraseña',
            child: TextFormField(
              controller: _passCtrl,
              decoration: const InputDecoration(hintText: '••••••••'),
              obscureText: true,
              validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () =>
                  _mostrarMensaje('Función de recuperación próximamente disponible'),
              child: const Text('¿Olvidaste tu contraseña?'),
            ),
          ),
          const SizedBox(height: 8),
          _loading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(onPressed: _login, child: const Text('Acceder')),
        ],
      ),
    );
  }

  Widget _formRegistro() {
    return Form(
      key: _formKeyRegistro,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LabeledField(
            label: 'Nombre completo',
            child: TextFormField(
              controller: _nombreCtrl,
              decoration: const InputDecoration(hintText: 'Ana García López'),
              validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
            ),
          ),
          const SizedBox(height: 14),
          LabeledField(
            label: 'Correo electrónico',
            child: TextFormField(
              controller: _correoRegCtrl,
              decoration: const InputDecoration(hintText: 'correo@ejemplo.com'),
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Requerido';
                if (!v.contains('@')) return 'Correo inválido';
                return null;
              },
            ),
          ),
          const SizedBox(height: 14),
          LabeledField(
            label: 'Contraseña',
            child: TextFormField(
              controller: _passRegCtrl,
              decoration: const InputDecoration(hintText: '••••••••'),
              obscureText: true,
              validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
            ),
          ),
          const SizedBox(height: 20),
          _loading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(onPressed: _registrar, child: const Text('Registrarse')),
        ],
      ),
    );
  }
}

class _Encabezado extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.layers_rounded, color: Colors.white, size: 30),
        ),
        const SizedBox(height: 14),
        const Text('AlertaZona',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text(
          'SISTEMA DE ALERTAS CIVILES',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _Segmentado extends StatelessWidget {
  final bool esLogin;
  final ValueChanged<bool> onChanged;
  const _Segmentado({required this.esLogin, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Expanded(child: _tab('Iniciar sesión', esLogin, () => onChanged(true))),
        Expanded(child: _tab('Crear cuenta', !esLogin, () => onChanged(false))),
      ]),
    );
  }

  Widget _tab(String label, bool activo, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: activo ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: activo ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

