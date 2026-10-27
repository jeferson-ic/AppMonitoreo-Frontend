import 'package:flutter/material.dart';
import '../models/incidente.dart';
import '../models/metricas.dart';
import '../services/api_service.dart';
import '../services/eventos_app.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../utils/fecha_utils.dart';
import '../widgets/badges.dart';
import '../widgets/mensaje_lista.dart';
import 'metrics_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<Incidente> _pendientes = [];
  int _validados = 0;
  int _rechazados = 0;
  bool _loading = true;
  String? _error;
  final Set<int> _procesando = {};

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _mostrarMensaje(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await StorageService.getToken();
      final res =
          await ApiService.get('/admin/incidentes/pendientes', token: token);
      if (!mounted) return;
      if (res.statusCode != 200) {
        setState(() => _error = 'No se pudieron cargar los reportes pendientes');
        return;
      }
      final pendientes = (ApiService.decodificar(res) as List)
          .map((j) => Incidente.fromJson(j))
          .toList()
        ..sort((a, b) => b.fechaIncidente.compareTo(a.fechaIncidente));
      setState(() => _pendientes = pendientes);

      // /incidentes excluye RECHAZADO; los totales salen de las métricas.
      final resMetricas = await ApiService.get('/admin/metricas', token: token);
      if (!mounted) return;
      if (resMetricas.statusCode == 200) {
        final m = Metricas.fromJson(ApiService.decodificar(resMetricas));
        setState(() {
          _validados = m.porEstado['VALIDADO'] ?? 0;
          _rechazados = m.porEstado['RECHAZADO'] ?? 0;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = ApiService.mensajeExcepcion(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _rechazar(Incidente inc) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rechazar reporte'),
        content: Text('¿Rechazar "${inc.tipoIncidente}"? '
            'Dejará de mostrarse en el mapa.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
    if (confirmar == true) await _accion(inc.idIncidente, 'rechazar');
  }

  Future<void> _accion(int id, String accion) async {
    if (_procesando.contains(id)) return;
    setState(() => _procesando.add(id));
    try {
      final token = await StorageService.getToken();
      final res =
          await ApiService.put('/admin/incidentes/$id/$accion', {}, token: token);
      if (!mounted) return;
      if (res.statusCode == 200) {
        _mostrarMensaje(accion == 'validar' ? 'Reporte validado' : 'Reporte rechazado');
        EventosApp.notificarIncidentes();
        await _cargar();
      } else if (res.statusCode == 404) {
        _mostrarMensaje('El reporte ya no existe');
        await _cargar();
      } else if (res.statusCode != 401) {
        _mostrarMensaje(ApiService.mensajeError(res));
      }
    } catch (e) {
      _mostrarMensaje(ApiService.mensajeExcepcion(e));
    } finally {
      if (mounted) setState(() => _procesando.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Panel administrativo',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                        Text('Revisión de reportes · Admin',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const MetricsScreen())),
                    icon: const Icon(Icons.bar_chart_rounded, size: 16),
                    label: const Text('Métricas'),
                    style: OutlinedButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                      child: _statCard('Pendientes', _pendientes.length, AppColors.warning)),
                  const SizedBox(width: 10),
                  Expanded(child: _statCard('Validados', _validados, AppColors.success)),
                  const SizedBox(width: 10),
                  Expanded(child: _statCard('Rechazados', _rechazados, AppColors.danger)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('REQUIEREN REVISIÓN (${_pendientes.length})',
                    style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6)),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _loading && _pendientes.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _cargar,
                      child: _error != null
                          ? MensajeLista(
                              mensaje: _error!,
                              icono: Icons.cloud_off_rounded,
                              onReintentar: _cargar)
                          : _pendientes.isEmpty
                              ? const MensajeLista(
                                  mensaje: 'No hay reportes pendientes',
                                  icono: Icons.task_alt_rounded)
                              : ListView.separated(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  itemCount: _pendientes.length,
                                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                                  itemBuilder: (_, i) {
                                    final inc = _pendientes[i];
                                    return _TarjetaPendiente(
                                      incidente: inc,
                                      procesando: _procesando.contains(inc.idIncidente),
                                      onValidar: () => _accion(inc.idIncidente, 'validar'),
                                      onRechazar: () => _rechazar(inc),
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

  Widget _statCard(String label, int valor, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text('$valor',
              style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _TarjetaPendiente extends StatelessWidget {
  final Incidente incidente;
  final bool procesando;
  final VoidCallback onValidar;
  final VoidCallback onRechazar;
  const _TarjetaPendiente({
    required this.incidente,
    required this.procesando,
    required this.onValidar,
    required this.onRechazar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              RiesgoDot(nivel: incidente.nivelRiesgo, size: 10),
              const SizedBox(width: 8),
              Expanded(
                child: Text(incidente.tipoIncidente,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
              const EstadoBadge(estado: 'PENDIENTE', dot: false),
            ],
          ),
          const SizedBox(height: 8),
          Text(incidente.descripcion,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 8),
          Text(
            '${formatearFechaHora(incidente.fechaIncidente)} · Riesgo ${incidente.nivelRiesgo.toLowerCase()}',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          if (procesando)
            const SizedBox(
              height: 40,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onRechazar,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                    ),
                    child: const Text('Rechazar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onValidar,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                      backgroundColor: AppColors.success,
                    ),
                    child: const Text('Validar'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
