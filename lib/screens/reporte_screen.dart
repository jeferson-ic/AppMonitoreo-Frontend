import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class ReporteScreen extends StatefulWidget {
  final Position? posicionInicial;
  const ReporteScreen({super.key, this.posicionInicial});
  @override
  State<ReporteScreen> createState() => _ReporteScreenState();
}

class _ReporteScreenState extends State<ReporteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  List<String> _tipos = [];
  String? _tipoSeleccionado;
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
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reporte enviado correctamente')));
        Navigator.pop(context, true);
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
    return Scaffold(
      appBar: AppBar(title: const Text('Reportar incidente')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(children: [
            _loadingTipos
                ? const CircularProgressIndicator()
                : DropdownButtonFormField<String>(
                    initialValue: _tipoSeleccionado,
                    decoration:
                        const InputDecoration(labelText: 'Tipo de incidente'),
                    items: _tipos
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) => setState(() => _tipoSeleccionado = v),
                    validator: (v) => v == null ? 'Selecciona un tipo' : null,
                  ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Descripción'),
              maxLines: 3,
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Requerido' : null,
            ),
            if (widget.posicionInicial != null) ...[
              const SizedBox(height: 8),
              Text(
                'Ubicación: ${widget.posicionInicial!.latitude.toStringAsFixed(5)}, '
                '${widget.posicionInicial!.longitude.toStringAsFixed(5)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 24),
            _loading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                        onPressed: _enviar,
                        child: const Text('Enviar reporte')),
                  ),
          ]),
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
