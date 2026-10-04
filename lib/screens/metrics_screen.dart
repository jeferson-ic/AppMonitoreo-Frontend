import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/incidente.dart';
import '../models/metricas.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class MetricsScreen extends StatefulWidget {
  const MetricsScreen({super.key});
  @override
  State<MetricsScreen> createState() => _MetricsScreenState();
}

class _MetricsScreenState extends State<MetricsScreen> {
  Metricas? _metricas;
  List<Incidente> _todos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final token = await StorageService.getToken();
      final resMetricas = await ApiService.get('/admin/metricas', token: token);
      final resIncidentes = await ApiService.get('/incidentes', token: token);
      if (resMetricas.statusCode == 200) {
        _metricas = Metricas.fromJson(jsonDecode(resMetricas.body));
      }
      if (resIncidentes.statusCode == 200) {
        _todos = (jsonDecode(resIncidentes.body) as List)
            .map((j) => Incidente.fromJson(j))
            .toList();
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Map<String, int> _conteoPor(String Function(Incidente) key) {
    final mapa = <String, int>{};
    for (final i in _todos) {
      final k = key(i);
      mapa[k] = (mapa[k] ?? 0) + 1;
    }
    return mapa;
  }

  @override
  Widget build(BuildContext context) {
    final m = _metricas;

    final porTipo = _conteoPor((i) => i.tipoIncidente);
    final tipoTop = porTipo.entries.isEmpty
        ? null
        : (porTipo.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first;
    final tiposOrdenados = porTipo.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxTipo = tiposOrdenados.isEmpty ? 1 : tiposOrdenados.first.value;

    final porRiesgo = _conteoPor((i) => i.nivelRiesgo);
    final totalRiesgo = _todos.length;

    return Scaffold(
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : m == null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('No se pudieron cargar las métricas',
                            style: TextStyle(color: AppColors.textMuted)),
                        const SizedBox(height: 12),
                        OutlinedButton(onPressed: _cargar, child: const Text('Reintentar')),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Panel de métricas',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                                Text('Datos en vivo desde el servidor',
                                    style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                              ],
                            ),
                          ),
                          IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar),
                        ],
                      ),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.35,
                        children: [
                          _tile(
                            icon: Icons.list_alt_rounded,
                            color: AppColors.primaryLight,
                            valor: '${m.totalIncidentes}',
                            label: 'Total de reportes',
                            sub: '${m.porEstado['PENDIENTE'] ?? 0} pendientes',
                          ),
                          _tile(
                            icon: Icons.verified_rounded,
                            color: AppColors.success,
                            valor: '${m.porcentajeValidacionAutomatica.round()}%',
                            label: 'Validados automáticamente',
                            sub: '${m.validacionesAutomaticas} de ${m.validacionesAutomaticas + m.validacionesManuales}',
                          ),
                          _tile(
                            icon: Icons.bar_chart_rounded,
                            color: AppColors.warning,
                            valor: tipoTop?.key ?? '—',
                            label: 'Tipo más frecuente',
                            sub: tipoTop == null ? 'Sin datos' : '${tipoTop.value} reportes',
                            valorPequeno: true,
                          ),
                          _tile(
                            icon: Icons.people_alt_rounded,
                            color: AppColors.purple,
                            valor: '${m.totalUsuarios}',
                            label: 'Usuarios registrados',
                            sub: '${m.usuariosActivos} activos',
                          ),
                          _tile(
                            icon: Icons.notifications_active_rounded,
                            color: AppColors.danger,
                            valor: '${m.totalAlertasRiesgoAlto}',
                            label: 'Alertas de riesgo alto',
                            sub: 'Total acumulado',
                          ),
                          _tile(
                            icon: Icons.person_off_rounded,
                            color: AppColors.riesgoAlto,
                            valor: '${m.porEstado['RECHAZADO'] ?? 0}',
                            label: 'Reportes rechazados',
                            sub: '${m.porEstado['ELIMINADO'] ?? 0} eliminados',
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _seccion(
                        titulo: 'Zonas más riesgosas',
                        subtitulo: 'Mayor concentración de incidentes',
                        child: m.zonasMasRiesgosas.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Text('Sin datos disponibles',
                                    style: TextStyle(color: AppColors.textMuted)),
                              )
                            : Column(
                                children: m.zonasMasRiesgosas.take(5).map((z) {
                                  final maxCantidad = m.zonasMasRiesgosas
                                      .map((e) => e.cantidad)
                                      .reduce((a, b) => a > b ? a : b);
                                  return _barraFila(
                                    label:
                                        '${z.celdaLat.toStringAsFixed(3)}, ${z.celdaLng.toStringAsFixed(3)}',
                                    valor: z.cantidad,
                                    maximo: maxCantidad,
                                    color: AppColors.riesgoAlto,
                                  );
                                }).toList(),
                              ),
                      ),
                      const SizedBox(height: 16),
                      _seccion(
                        titulo: 'Incidentes por tipo',
                        subtitulo: 'Totales acumulados',
                        child: tiposOrdenados.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Text('Sin datos disponibles',
                                    style: TextStyle(color: AppColors.textMuted)),
                              )
                            : Column(
                                children: tiposOrdenados.take(5).map((e) {
                                  return _barraFila(
                                    label: e.key,
                                    valor: e.value,
                                    maximo: maxTipo,
                                    color: AppColors.primaryLight,
                                  );
                                }).toList(),
                              ),
                      ),
                      const SizedBox(height: 16),
                      _seccion(
                        titulo: 'Distribución por nivel de riesgo',
                        subtitulo: null,
                        child: Column(
                          children: [
                            _barraFila(
                              label: 'Alto',
                              valor: porRiesgo['ALTO'] ?? 0,
                              maximo: totalRiesgo == 0 ? 1 : totalRiesgo,
                              color: AppColors.riesgoAlto,
                            ),
                            _barraFila(
                              label: 'Medio',
                              valor: porRiesgo['MEDIO'] ?? 0,
                              maximo: totalRiesgo == 0 ? 1 : totalRiesgo,
                              color: AppColors.riesgoMedio,
                            ),
                            _barraFila(
                              label: 'Bajo',
                              valor: porRiesgo['BAJO'] ?? 0,
                              maximo: totalRiesgo == 0 ? 1 : totalRiesgo,
                              color: AppColors.riesgoBajo,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required Color color,
    required String valor,
    required String label,
    required String sub,
    bool valorPequeno = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ],
          ),
          const Spacer(),
          Text(
            valor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: valorPequeno ? 16 : 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _seccion({required String titulo, String? subtitulo, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(titulo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              if (subtitulo != null)
                Text(subtitulo,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _barraFila({
    required String label,
    required int valor,
    required int maximo,
    required Color color,
  }) {
    final proporcion = maximo == 0 ? 0.0 : (valor / maximo).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: proporcion,
                minHeight: 10,
                backgroundColor: AppColors.surfaceAlt,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 24,
            child: Text('$valor',
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
