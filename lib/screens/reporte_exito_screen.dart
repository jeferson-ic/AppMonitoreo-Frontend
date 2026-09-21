import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ReporteExitoScreen extends StatelessWidget {
  final int idIncidente;
  final VoidCallback? onVerReportes;

  const ReporteExitoScreen({
    super.key,
    required this.idIncidente,
    this.onVerReportes,
  });

  String get _codigoSeguimiento {
    final anio = DateTime.now().year;
    final numero = idIncidente.toString().padLeft(4, '0');
    return 'INC-$anio-$numero';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 48),
              ),
              const SizedBox(height: 28),
              const Text('¡Reporte enviado!',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              const Text(
                'Tu incidente ha sido registrado y está siendo procesado por el sistema de validación automática.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ID DE SEGUIMIENTO',
                        style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.6)),
                    const SizedBox(height: 6),
                    Text(_codigoSeguimiento,
                        style: const TextStyle(
                            color: AppColors.primaryLight,
                            fontSize: 18,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    const Text('Recibirás una notificación cuando tu reporte sea validado.',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Volver al mapa'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    onVerReportes?.call();
                    Navigator.pop(context, true);
                  },
                  child: const Text('Ver mis reportes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
