import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/incidente.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../utils/fecha_utils.dart';
import '../widgets/badges.dart';
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

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final token = await StorageService.getToken();
      final res = await ApiService.get('/incidentes', token: token);
      if (res.statusCode == 200) {
        setState(() {
          _todos = (jsonDecode(res.body) as List)
              .map((j) => Incidente.fromJson(j))
              .toList();
        });
      }
    } catch (_) {}
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
                    onChanged: (v) => setState(() => _query = v),
                    decoration: const InputDecoration(
                      hintText: 'Buscar por tipo o descripción...',
                      prefixIcon: Icon(Icons.search, color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _resultados.isEmpty
                      ? const Center(
                          child: Text('Sin resultados',
                              style: TextStyle(color: AppColors.textMuted)))
                      : ListView.separated(
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
          ],
        ),
      ),
    );
  }
}
