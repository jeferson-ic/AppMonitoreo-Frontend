import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/incidente.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});
  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  List<Incidente> _reportes = [];
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
      final res = await ApiService.get('/incidentes/mis-reportes', token: token);
      if (res.statusCode == 200) {
        setState(() {
          _reportes = (jsonDecode(res.body) as List)
              .map((j) => Incidente.fromJson(j))
              .toList();
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Color _colorEstado(String estado) => switch (estado) {
        'VALIDADO' => Colors.green,
        'ELIMINADO' => Colors.red,
        _ => Colors.orange,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis reportes'), actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar),
      ]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _reportes.isEmpty
              ? const Center(child: Text('Aún no tienes reportes'))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _reportes.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (_, i) {
                    final r = _reportes[i];
                    return ListTile(
                      leading: Icon(Icons.warning_amber,
                          color: switch (r.nivelRiesgo) {
                            'ALTO' => Colors.red,
                            'MEDIO' => Colors.orange,
                            _ => Colors.yellow[700]
                          }),
                      title: Text(r.tipoIncidente),
                      subtitle: Text(r.descripcion),
                      trailing: Chip(
                        label: Text(r.estado,
                            style: const TextStyle(fontSize: 11)),
                        backgroundColor:
                            _colorEstado(r.estado).withValues(alpha: 0.2),
                      ),
                    );
                  },
                ),
    );
  }
}
