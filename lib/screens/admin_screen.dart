import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/incidente.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../utils/fecha_utils.dart';
import '../widgets/badges.dart';
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

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final token = await StorageService.getToken();
      final res =
          await ApiService.get('/admin/incidentes/pendientes', token: token);
      if (res.statusCode == 200) {
        setState(() {
          _pendientes = (jsonDecode(res.body) as List)
              .map((j) => Incidente.fromJson(j))
              .toList();
        });
      }
      final resTodos = await ApiService.get('/incidentes', token: token);
      if (resTodos.statusCode == 200) {
        final todos = (jsonDecode(resTodos.body) as List)
            .map((j) => Incidente.fromJson(j))
            .toList();
        setState(() {
          _validados = todos.where((i) => i.estado == 'VALIDADO').length;
          _rechazados = todos.where((i) => i.estado == 'RECHAZADO').length;
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _accion(int id, String accion) async {
    final token = await StorageService.getToken();
    final path = '/admin/incidentes/$id/$accion';
    final res = await ApiService.put(path, {}, token: token);
    if (!mounted) return;
    if (res.statusCode == 200) {
      _cargar();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Incidente $id → ${accion.toUpperCase()}')));
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
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _pendientes.isEmpty
                      ? const Center(
                          child: Text('No hay reportes pendientes',
                              style: TextStyle(color: AppColors.textMuted)))
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: _pendientes.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final inc = _pendientes[i];
                            return _TarjetaPendiente(
                              incidente: inc,
                              onValidar: () => _accion(inc.idIncidente, 'validar'),
                              onRechazar: () => _accion(inc.idIncidente, 'rechazar'),
                            );
                          },
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
  final VoidCallback onValidar;
  final VoidCallback onRechazar;
  const _TarjetaPendiente({
    required this.incidente,
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
            '${formatearFecha(incidente.fechaIncidente)} · ${incidente.reportesCoincidentes} reportes',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 12),
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
