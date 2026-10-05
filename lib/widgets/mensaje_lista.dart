import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Estado vacío o de error para usar dentro de un RefreshIndicator: es
/// desplazable, así que también se puede "jalar para refrescar".
class MensajeLista extends StatelessWidget {
  final String mensaje;
  final IconData icono;
  final VoidCallback? onReintentar;

  const MensajeLista({
    super.key,
    required this.mensaje,
    this.icono = Icons.inbox_outlined,
    this.onReintentar,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(32, 80, 32, 32),
      children: [
        Icon(icono, size: 40, color: AppColors.textMuted),
        const SizedBox(height: 12),
        Text(mensaje,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted)),
        if (onReintentar != null) ...[
          const SizedBox(height: 16),
          Center(
            child: OutlinedButton.icon(
              onPressed: onReintentar,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reintentar'),
            ),
          ),
        ],
      ],
    );
  }
}
