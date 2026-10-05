import 'package:flutter/material.dart';
import '../models/incidente.dart';
import '../services/api_service.dart';
import '../services/eventos_app.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../utils/fecha_utils.dart';
import '../widgets/badges.dart';
import '../widgets/mensaje_lista.dart';
import 'incidente_detalle_screen.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});
  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  List<Incidente> _reportes = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    EventosApp.incidentesCambiaron.addListener(_cargar);
    _cargar();
  }

  @override
  void dispose() {
    EventosApp.incidentesCambiaron.removeListener(_cargar);
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await StorageService.getToken();
      final res = await ApiService.get('/incidentes/mis-reportes', token: token);
      if (!mounted) return;
      if (res.statusCode == 200) {
        setState(() {
          _reportes = (ApiService.decodificar(res) as List)
              .map((j) => Incidente.fromJson(j))
              .toList();
        });
      } else {
        setState(() => _error = 'No se pudieron cargar tus reportes');
      }
    } catch (e) {
      if (mounted) setState(() => _error = ApiService.mensajeExcepcion(e));
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Mis reportes',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  ),
                  IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar),
                ],
              ),
            ),
            Expanded(
              child: _loading && _reportes.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _cargar,
                      child: _error != null
                      ? MensajeLista(
                          mensaje: _error!,
                          icono: Icons.cloud_off_rounded,
                          onReintentar: _cargar)
                      : _reportes.isEmpty
                      ? const MensajeLista(
                          mensaje: 'Aún no tienes reportes.\n'
                              'Usa "Reportar incidente" en el mapa para crear uno.')
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: _reportes.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final r = _reportes[i];
                            return _TarjetaReporte(
                              incidente: r,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        IncidenteDetalleScreen(incidente: r)),
                              ),
                            );
                          },
                        ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaReporte extends StatelessWidget {
  final Incidente incidente;
  final VoidCallback onTap;
  const _TarjetaReporte({required this.incidente, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.riesgoColor(incidente.nivelRiesgo).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.warning_amber_rounded,
                  color: AppColors.riesgoColor(incidente.nivelRiesgo)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(incidente.tipoIncidente,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(incidente.descripcion,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(formatearFecha(incidente.fechaIncidente),
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            EstadoBadge(estado: incidente.estado, dot: false),
          ],
        ),
      ),
    );
  }
}
