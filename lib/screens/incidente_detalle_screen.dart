import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/incidente.dart';
import '../theme/app_theme.dart';
import '../utils/fecha_utils.dart';
import '../widgets/badges.dart';

class IncidenteDetalleScreen extends StatefulWidget {
  final Incidente incidente;
  const IncidenteDetalleScreen({super.key, required this.incidente});

  @override
  State<IncidenteDetalleScreen> createState() => _IncidenteDetalleScreenState();
}

class _IncidenteDetalleScreenState extends State<IncidenteDetalleScreen> {
  bool _siguiendo = false;

  String get _codigo => 'INC-${widget.incidente.idIncidente.toString().padLeft(3, '0')}';

  String get _fechaFormateada => formatearFechaHora(widget.incidente.fechaIncidente);

  void _compartir() {
    final inc = widget.incidente;
    final texto = '$_codigo · ${inc.tipoIncidente}\n${inc.descripcion}\n'
        'Ubicación: ${inc.latitud.toStringAsFixed(5)}, ${inc.longitud.toStringAsFixed(5)}';
    Clipboard.setData(ClipboardData(text: texto));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Copiado al portapapeles')));
  }

  @override
  Widget build(BuildContext context) {
    final inc = widget.incidente;
    final posicion = LatLng(inc.latitud, inc.longitud);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(inc.tipoIncidente,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w800)),
                        Text(_codigo,
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                  RiesgoBadge(nivel: inc.nivelRiesgo),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      height: 160,
                      child: IgnorePointer(
                        child: GoogleMap(
                          initialCameraPosition:
                              CameraPosition(target: posicion, zoom: 15),
                          markers: {
                            Marker(
                              markerId: const MarkerId('detalle'),
                              position: posicion,
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                switch (inc.nivelRiesgo.toUpperCase()) {
                                  'ALTO' => BitmapDescriptor.hueRed,
                                  'MEDIO' => BitmapDescriptor.hueOrange,
                                  _ => BitmapDescriptor.hueAzure,
                                },
                              ),
                            ),
                          },
                          liteModeEnabled: true,
                          zoomControlsEnabled: false,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  EstadoBadge(estado: inc.estado),
                  const SizedBox(height: 16),
                  _card(
                    label: 'DESCRIPCIÓN',
                    child: Text(inc.descripcion, style: const TextStyle(height: 1.4)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _card(
                          label: 'TIPO',
                          child: Row(children: [
                            const Icon(Icons.warning_amber_rounded,
                                size: 16, color: AppColors.warning),
                            const SizedBox(width: 6),
                            Flexible(child: Text(inc.tipoIncidente)),
                          ]),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _card(
                          label: 'FECHA',
                          child: Row(children: [
                            const Icon(Icons.schedule,
                                size: 16, color: AppColors.primaryLight),
                            const SizedBox(width: 6),
                            Flexible(
                                child: Text(_fechaFormateada,
                                    overflow: TextOverflow.ellipsis)),
                          ]),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _card(
                    label: 'UBICACIÓN',
                    child: Row(children: [
                      const Icon(Icons.location_on, size: 16, color: AppColors.danger),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                            '${inc.latitud.toStringAsFixed(5)}, ${inc.longitud.toStringAsFixed(5)}'),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  _card(
                    label: 'REPORTES COINCIDENTES',
                    child: Row(children: [
                      const Icon(Icons.people_alt_rounded,
                          size: 16, color: AppColors.purple),
                      const SizedBox(width: 6),
                      Text('${inc.reportesCoincidentes} usuarios'),
                    ]),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _compartir,
                          icon: const Icon(Icons.ios_share, size: 18),
                          label: const Text('Compartir'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => setState(() => _siguiendo = !_siguiendo),
                          icon: Icon(
                              _siguiendo ? Icons.check_circle : Icons.notifications_none,
                              size: 18,
                              color: _siguiendo ? AppColors.success : null),
                          label: Text(_siguiendo ? 'Siguiendo' : 'Seguir'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({required String label, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6)),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}
