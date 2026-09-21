import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/labeled_field.dart';
import 'reporte_exito_screen.dart';

class ReporteScreen extends StatefulWidget {
  final Position? posicionInicial;
  final VoidCallback? onVerReportes;
  const ReporteScreen({super.key, this.posicionInicial, this.onVerReportes});
  @override
  State<ReporteScreen> createState() => _ReporteScreenState();
}

class _ReporteScreenState extends State<ReporteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  List<String> _tipos = [];
  String? _tipoSeleccionado;
  String _urgencia = 'MEDIO';
  bool _loading = false;
  bool _loadingTipos = true;

  @override
  void initState() {
    super.initState();
    _cargarTipos();
  }

  Future<void> _cargarTipos() async {
    try {
      final token = await StorageService.getToken();
      final res = await ApiService.get('/incidentes/tipos', token: token);
      if (res.statusCode == 200) {
        final lista = (jsonDecode(res.body) as List).cast<String>();
        setState(() {
          _tipos = lista;
          _tipoSeleccionado = lista.isNotEmpty ? lista.first : null;
          _loadingTipos = false;
        });
      }
    } catch (_) {
      setState(() => _loadingTipos = false);
    }
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_tipoSeleccionado == null) return;
    setState(() => _loading = true);
    try {
      final token = await StorageService.getToken();
      final pos = widget.posicionInicial;
      final res = await ApiService.post('/incidentes', {
        'tipoIncidente': _tipoSeleccionado,
        'descripcion': _descCtrl.text.trim(),
        'latitud': pos?.latitude ?? 0.0,
        'longitud': pos?.longitude ?? 0.0,
      }, token: token);
      if (!mounted) return;
      if (res.statusCode == 201) {
        int idIncidente = 0;
        try {
          final data = jsonDecode(res.body);
          idIncidente = data['idIncidente'] ?? 0;
        } catch (_) {}
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ReporteExitoScreen(
              idIncidente: idIncidente,
              onVerReportes: widget.onVerReportes,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: ${res.body}')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pos = widget.posicionInicial;
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
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Reportar incidente',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      Text('Completa la información',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LabeledField(
                        label: 'Tipo de incidente',
                        child: _loadingTipos
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 14),
                                child: LinearProgressIndicator(),
                              )
                            : DropdownButtonFormField<String>(
                                initialValue: _tipoSeleccionado,
                                decoration: const InputDecoration(),
                                dropdownColor: AppColors.surface,
                                items: _tipos
                                    .map((t) =>
                                        DropdownMenuItem(value: t, child: Text(t)))
                                    .toList(),
                                onChanged: (v) => setState(() => _tipoSeleccionado = v),
                                validator: (v) => v == null ? 'Selecciona un tipo' : null,
                              ),
                      ),
                      const SizedBox(height: 16),
                      LabeledField(
                        label: 'Descripción',
                        child: TextFormField(
                          controller: _descCtrl,
                          decoration: const InputDecoration(
                              hintText: 'Describe brevemente lo que está ocurriendo...'),
                          maxLines: 3,
                          maxLength: 280,
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Requerido' : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      LabeledField(
                        label: 'Ubicación',
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on,
                                  size: 18, color: AppColors.primaryLight),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  pos != null
                                      ? '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}'
                                      : 'Obteniendo ubicación...',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (pos != null)
                                const Padding(
                                  padding: EdgeInsets.only(left: 6),
                                  child: Text('GPS✓',
                                      style: TextStyle(
                                          color: AppColors.success,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700)),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      LabeledField(
                        label: 'Fotografía (opcional)',
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Función próximamente disponible'))),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 28),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppColors.border, style: BorderStyle.solid),
                              color: AppColors.surfaceAlt,
                            ),
                            child: const Column(
                              children: [
                                Icon(Icons.camera_alt_outlined,
                                    color: AppColors.textMuted, size: 28),
                                SizedBox(height: 8),
                                Text('Toca para añadir foto',
                                    style: TextStyle(color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      LabeledField(
                        label: 'Nivel de urgencia percibido',
                        child: Row(
                          children: [
                            Expanded(
                                child: _urgenciaChip('BAJO', 'Bajo', AppColors.riesgoBajo)),
                            const SizedBox(width: 10),
                            Expanded(
                                child: _urgenciaChip(
                                    'MEDIO', 'Medio', AppColors.riesgoMedio)),
                            const SizedBox(width: 10),
                            Expanded(
                                child:
                                    _urgenciaChip('ALTO', 'Alto', AppColors.riesgoAlto)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _loading
                          ? const Center(child: CircularProgressIndicator())
                          : SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                  onPressed: _enviar, child: const Text('Enviar reporte')),
                            ),
                      const SizedBox(height: 10),
                      const Text(
                        'Tu reporte será revisado por el sistema de validación automática',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _urgenciaChip(String valor, String label, Color color) {
    final activo = _urgencia == valor;
    return GestureDetector(
      onTap: () => setState(() => _urgencia = valor),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: activo ? color.withValues(alpha: 0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: activo ? color : AppColors.border, width: activo ? 1.5 : 1),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: activo ? color : AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }
}
