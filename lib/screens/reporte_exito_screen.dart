import 'package:flutter/material.dart';
import '../models/incidente.dart';
import '../theme/app_theme.dart';

class ReporteExitoScreen extends StatelessWidget {
  final int idIncidente;
  final String estado;
  final VoidCallback? onVerReportes;

  const ReporteExitoScreen({
    super.key,
    required this.idIncidente,
    this.estado = 'PENDIENTE',
    this.onVerReportes,
  });

  bool get _yaValidado => estado.toUpperCase() == 'VALIDADO';

  String get _codigoSeguimiento => Incidente.codigoDe(idIncidente);

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
              Text(
                _yaValidado
                    ? 'Tu incidente coincidió con otros reportes cercanos y ya fue validado automáticamente.'
                    : 'Tu incidente fue registrado. Se confirmará cuando otros usuarios reporten lo mismo en la zona o cuando un moderador lo revise.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_codigoSeguimiento,
                            style: const TextStyle(
                                color: AppColors.primaryLight,
                                fontSize: 18,
                                fontWeight: FontWeight.w800)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (_yaValidado ? AppColors.success : AppColors.warning)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            AppColors.estadoLabel(estado),
                            style: TextStyle(
                                color: _yaValidado ? AppColors.success : AppColors.warning,
                                fontSize: 11,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _yaValidado
                          ? 'Ya cuenta para las alertas y zonas de riesgo del mapa.'
                          : 'Se ve en el mapa como "sin confirmar" y aún no genera alertas. Revisa su estado en Mis reportes.',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
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
