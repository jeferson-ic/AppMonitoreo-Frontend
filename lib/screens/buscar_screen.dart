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

class BuscarScreen extends StatefulWidget {
  const BuscarScreen({super.key});
  @override
  State<BuscarScreen> createState() => _BuscarScreenState();
}

class _BuscarScreenState extends State<BuscarScreen> {
  final _queryCtrl = TextEditingController();
  List<Incidente> _todos = [];
  bool _loading = true;
  String _query = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    EventosApp.incidentesCambiaron.addListener(_cargar);
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await StorageService.getToken();
      final res = await ApiService.get('/incidentes', token: token);
      if (!mounted) return;
      if (res.statusCode == 200) {
        setState(() {
          _todos = (ApiService.decodificar(res) as List)
              .map((j) => Incidente.fromJson(j))
              .toList();
        });
      } else {
        setState(() => _error = 'No se pudieron cargar los incidentes');
      }
    } catch (e) {
      if (mounted) setState(() => _error = ApiService.mensajeExcepcion(e));
    }
    if (mounted) setState(() => _loading = false);
  }

  List<Incidente> get _resultados {
    if (_query.isEmpty) return _todos;
    final q = _query.toLowerCase();
    return _todos
        .where((i) =>
            i.tipoIncidente.toLowerCase().contains(q) ||
            i.descripcion.toLowerCase().contains(q))
        .toList();
  }

  @override
  void dispose() {
    EventosApp.incidentesCambiaron.removeListener(_cargar);
    _queryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Buscar incidentes',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _queryCtrl,
                    onChanged: (v) => setState(() => _query = v.trim()),
                    decoration: InputDecoration(
                      hintText: 'Buscar por tipo o descripción...',
                      prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              tooltip: 'Limpiar',
                              onPressed: () {
                                _queryCtrl.clear();
                                setState(() => _query = '');
                              },
                            ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading && _todos.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _cargar,
                      child: _error != null
                      ? MensajeLista(
                          mensaje: _error!,
                          icono: Icons.cloud_off_rounded,
                          onReintentar: _cargar)
                      : _resultados.isEmpty
                      ? MensajeLista(
                          mensaje: _query.isEmpty
                              ? 'No hay incidentes registrados'
                              : 'Sin resultados para "$_query"',
                          icono: Icons.search_off_rounded)
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.all(16),
                          itemCount: _resultados.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final inc = _resultados[i];
                            return InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        IncidenteDetalleScreen(incidente: inc)),
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    RiesgoDot(nivel: inc.nivelRiesgo, size: 12),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(inc.tipoIncidente,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w700)),
                                          const SizedBox(height: 2),
                                          Text(inc.descripcion,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  color: AppColors.textMuted,
                                                  fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    Text(formatearFecha(inc.fechaIncidente),
                                        style: const TextStyle(
                                            color: AppColors.textMuted, fontSize: 11)),
                                  ],
                                ),
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
