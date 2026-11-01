import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/firebase_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/labeled_field.dart';
import '../widgets/logo_app.dart';
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
  final _passConfirmCtrl = TextEditingController();

  bool _loading = false;
  bool _verPass = false;
  bool _verPassReg = false;

  static final _regexCorreo = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  // Mismas reglas que RegisterRequest del backend.
  static final _regexLetra = RegExp(r'[A-Za-z]');
  static final _regexNumero = RegExp(r'[0-9]');

  static String? _validarCorreo(String? v) {
    final correo = v?.trim() ?? '';
    if (correo.isEmpty) return 'Requerido';
    if (!_regexCorreo.hasMatch(correo)) return 'Correo inválido';
    return null;
  }

  static String? _validarPassRegistro(String? v) {
    if (v == null || v.isEmpty) return 'Requerido';
    if (v.length < 8) return 'Mínimo 8 caracteres';
    if (v.length > 72) return 'Máximo 72 caracteres';
    if (!_regexLetra.hasMatch(v) || !_regexNumero.hasMatch(v)) {
      return 'Debe incluir letras y números';
    }
    return null;
  }

  Widget _botonVer(bool visible, VoidCallback onPressed) => IconButton(
        icon: Icon(visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: AppColors.textMuted, size: 20),
        tooltip: visible ? 'Ocultar contraseña' : 'Mostrar contraseña',
        onPressed: onPressed,
      );

  @override
  void dispose() {
    _correoCtrl.dispose();
    _passCtrl.dispose();
    _nombreCtrl.dispose();
    _correoRegCtrl.dispose();
    _passRegCtrl.dispose();
    _passConfirmCtrl.dispose();
    super.dispose();
  }

  void _mostrarMensaje(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  /// Inicia sesión y navega al inicio. Las excepciones de red se propagan.
  Future<void> _autenticar(String correo, String contrasena) async {
    final res = await ApiService.post('/auth/login', {
      'correo': correo,
      'contrasena': contrasena,
    });
    if (!mounted) return;
    if (res.statusCode == 200) {
      final data = ApiService.decodificar(res);
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
    } else if (res.statusCode == 401) {
      _mostrarMensaje('Correo o contraseña incorrectos');
    } else {
      _mostrarMensaje(ApiService.mensajeError(res));
    }
  }

  Future<void> _login() async {
    if (_loading || !_formKeyLogin.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      await _autenticar(_correoCtrl.text.trim(), _passCtrl.text);
    } catch (e) {
      _mostrarMensaje(ApiService.mensajeExcepcion(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _registrar() async {
    if (_loading || !_formKeyRegistro.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      final correo = _correoRegCtrl.text.trim();
      final contrasena = _passRegCtrl.text;
      final res = await ApiService.post('/auth/register', {
        'nombre': _nombreCtrl.text.trim(),
        'correo': correo,
        'contrasena': contrasena,
      });
      if (!mounted) return;
      if (res.statusCode == 201) {
        // Se deja el login relleno por si el inicio automático falla.
        _correoCtrl.text = correo;
        _passCtrl.text = contrasena;
        try {
          await _autenticar(correo, contrasena);
        } catch (e) {
          _mostrarMensaje('Cuenta creada. ${ApiService.mensajeExcepcion(e)}');
        }
        if (mounted) setState(() => _esLogin = true);
      } else {
        _mostrarMensaje(
            ApiService.mensajeError(res, porDefecto: 'No se pudo completar el registro'));
      }
    } catch (e) {
      _mostrarMensaje(ApiService.mensajeExcepcion(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        // Tocar fuera de los campos cierra el teclado.
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              children: [
                const LogoApp(),
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
                        onChanged: _loading ? null : (v) => setState(() => _esLogin = v),
                      ),
                      const SizedBox(height: 20),
                      if (_esLogin) _formLogin() else _formRegistro(),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Al continuar aceptas los Términos de servicio',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _botonEnviar(String texto, VoidCallback onPressed) {
    // Sigue activo mientras carga para no verse gris; los handlers ignoran
    // toques repetidos con _loading.
    return ElevatedButton(
      onPressed: onPressed,
      child: _loading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
            )
          : Text(texto),
    );
  }

  Widget _formLogin() {
    return Form(
      key: _formKeyLogin,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LabeledField(
              label: 'Correo electrónico',
              child: TextFormField(
                controller: _correoCtrl,
                enabled: !_loading,
                decoration: const InputDecoration(hintText: 'correo@ejemplo.com'),
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email, AutofillHints.username],
                autocorrect: false,
                textInputAction: TextInputAction.next,
                validator: _validarCorreo,
              ),
            ),
            const SizedBox(height: 14),
            LabeledField(
              label: 'Contraseña',
              child: TextFormField(
                controller: _passCtrl,
                enabled: !_loading,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  suffixIcon: _botonVer(_verPass, () => setState(() => _verPass = !_verPass)),
                ),
                obscureText: !_verPass,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _login(),
                validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
              ),
            ),
            const SizedBox(height: 24),
            _botonEnviar('Acceder', _login),
          ],
        ),
      ),
    );
  }

  Widget _formRegistro() {
    return Form(
      key: _formKeyRegistro,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LabeledField(
              label: 'Nombre completo',
              child: TextFormField(
                controller: _nombreCtrl,
                enabled: !_loading,
                decoration: const InputDecoration(hintText: 'Ana García López'),
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
                textInputAction: TextInputAction.next,
                maxLength: 100,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
              ),
            ),
            const SizedBox(height: 14),
            LabeledField(
              label: 'Correo electrónico',
              child: TextFormField(
                controller: _correoRegCtrl,
                enabled: !_loading,
                decoration: const InputDecoration(hintText: 'correo@ejemplo.com'),
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                autocorrect: false,
                textInputAction: TextInputAction.next,
                validator: _validarCorreo,
              ),
            ),
            const SizedBox(height: 14),
            LabeledField(
              label: 'Contraseña',
              child: TextFormField(
                controller: _passRegCtrl,
                enabled: !_loading,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  suffixIcon:
                      _botonVer(_verPassReg, () => setState(() => _verPassReg = !_verPassReg)),
                ),
                obscureText: !_verPassReg,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.next,
                validator: _validarPassRegistro,
              ),
            ),
            const SizedBox(height: 10),
            _RequisitosPass(controller: _passRegCtrl),
            const SizedBox(height: 14),
            LabeledField(
              label: 'Confirmar contraseña',
              child: TextFormField(
                controller: _passConfirmCtrl,
                enabled: !_loading,
                decoration: const InputDecoration(hintText: '••••••••'),
                obscureText: !_verPassReg,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _registrar(),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requerido';
                  if (v != _passRegCtrl.text) return 'Las contraseñas no coinciden';
                  return null;
                },
              ),
            ),
            const SizedBox(height: 24),
            _botonEnviar('Registrarse', _registrar),
          ],
        ),
      ),
    );
  }
}

/// Lista de requisitos de la contraseña que se marca mientras se escribe.
class _RequisitosPass extends StatelessWidget {
  final TextEditingController controller;
  const _RequisitosPass({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (_, valor, _) {
        final pass = valor.text;
        return Wrap(
          spacing: 14,
          runSpacing: 6,
          children: [
            _item('8+ caracteres', pass.length >= 8 && pass.length <= 72),
            _item('Letras', _AuthScreenState._regexLetra.hasMatch(pass)),
            _item('Números', _AuthScreenState._regexNumero.hasMatch(pass)),
          ],
        );
      },
    );
  }

  Widget _item(String texto, bool cumple) {
    final color = cumple ? AppColors.success : AppColors.textMuted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(cumple ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 14, color: color),
        const SizedBox(width: 4),
        Text(texto, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }
}

class _Segmentado extends StatelessWidget {
  final bool esLogin;
  final ValueChanged<bool>? onChanged;
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
        Expanded(child: _tab('Iniciar sesión', esLogin, true)),
        Expanded(child: _tab('Crear cuenta', !esLogin, false)),
      ]),
    );
  }

  Widget _tab(String label, bool activo, bool valor) {
    final onTap = onChanged == null ? null : () => onChanged!(valor);
    return Semantics(
      button: true,
      selected: activo,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
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
      ),
    );
  }
}
