import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/incidente.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<Incidente> _pendientes = [];
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
      appBar: AppBar(
        title: const Text('Panel Admin — Pendientes'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _pendientes.isEmpty
              ? const Center(child: Text('No hay reportes pendientes'))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _pendientes.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (_, i) {
                    final inc = _pendientes[i];
                    return Card(
                      child: ListTile(
                        title: Text('${inc.tipoIncidente} · ${inc.nivelRiesgo}'),
                        subtitle: Text(inc.descripcion),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check_circle,
                                  color: Colors.green),
                              tooltip: 'Validar',
                              onPressed: () =>
                                  _accion(inc.idIncidente, 'validar'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Eliminar',
                              onPressed: () =>
                                  _accion(inc.idIncidente, 'eliminar'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
