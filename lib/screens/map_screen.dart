import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/incidente.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'incidente_detalle_screen.dart';
import 'reporte_screen.dart';

class MapScreen extends StatefulWidget {
  final void Function(int indice)? onNavegarTab;
  const MapScreen({super.key, this.onNavegarTab});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  Position? _posicion;
  List<Incidente> _incidentes = [];
  Set<Circle> _zonasCercles = {};
  Timer? _alertTimer;
  final _notifPlugin = FlutterLocalNotificationsPlugin();
  final Set<int> _alertasYaNotificadas = {};

  String _filtroRiesgo = 'TODOS';
  String? _filtroTipo;

  static const _radioAlertaKm = 1.0;

  @override
  void initState() {
    super.initState();
    _initNotificaciones();
    _obtenerUbicacion();
  }

  Future<void> _initNotificaciones() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _notifPlugin.initialize(
      settings: const InitializationSettings(android: androidSettings),
    );
    const channel = AndroidNotificationChannel(
      'zonas_peligrosas', 'Alertas de zonas peligrosas',
      importance: Importance.high,
    );
    await _notifPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _obtenerUbicacion() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permiso de ubicación denegado')));
      }
      return;
    }
    final pos = await Geolocator.getCurrentPosition();
    setState(() => _posicion = pos);
    _mapController?.animateCamera(
        CameraUpdate.newLatLng(LatLng(pos.latitude, pos.longitude)));
    await _cargarIncidentes();
    _iniciarPolling();
  }

  Future<void> _cargarIncidentes() async {
    try {
      final token = await StorageService.getToken();
      final res = await ApiService.get('/incidentes', token: token);
      if (res.statusCode == 200) {
        final lista = (jsonDecode(res.body) as List)
            .map((j) => Incidente.fromJson(j))
            .toList();
        setState(() => _incidentes = lista);
        await _cargarZonasRiesgo();
      }
    } catch (_) {}
  }

  List<Incidente> get _incidentesFiltrados => _incidentes.where((i) {
        final pasaRiesgo = _filtroRiesgo == 'TODOS' || i.nivelRiesgo == _filtroRiesgo;
        final pasaTipo = _filtroTipo == null || i.tipoIncidente == _filtroTipo;
        return pasaRiesgo && pasaTipo;
      }).toList();

  Set<Marker> get _marcadores => _incidentesFiltrados.map(_incidenteAMarcador).toSet();

  Marker _incidenteAMarcador(Incidente inc) {
    final hue = switch (inc.nivelRiesgo) {
      'ALTO' => BitmapDescriptor.hueRed,
      'MEDIO' => BitmapDescriptor.hueOrange,
      _ => BitmapDescriptor.hueAzure,
    };
    return Marker(
      markerId: MarkerId(inc.idIncidente.toString()),
      position: LatLng(inc.latitud, inc.longitud),
      icon: BitmapDescriptor.defaultMarkerWithHue(hue),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => IncidenteDetalleScreen(incidente: inc)),
      ),
    );
  }

  Future<void> _cargarZonasRiesgo() async {
    try {
      final token = await StorageService.getToken();
      final res = await ApiService.get('/incidentes/zonas-riesgo', token: token);
      if (res.statusCode == 200) {
        final zonas = jsonDecode(res.body) as List;
        setState(() {
          _zonasCercles = zonas.map((z) {
            final lat = (z['celda_lat'] as num).toDouble();
            final lng = (z['celda_lng'] as num).toDouble();
            final cantidad = (z['cantidad'] as num).toInt();
            return Circle(
              circleId: CircleId('$lat,$lng'),
              center: LatLng(lat, lng),
              radius: 150.0 + cantidad * 30,
              fillColor: Colors.red.withValues(alpha: 0.25),
              strokeColor: Colors.red,
              strokeWidth: 1,
            );
          }).toSet();
        });
      }
    } catch (_) {}
  }

  void _iniciarPolling() {
    _alertTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (_posicion == null) return;
      try {
        final token = await StorageService.getToken();
        final res = await ApiService.get('/incidentes/cercanos',
            token: token,
            queryParams: {
              'lat': _posicion!.latitude.toString(),
              'lng': _posicion!.longitude.toString(),
              'radioKm': _radioAlertaKm.toString(),
            });
        if (res.statusCode == 200) {
          final cercanos = (jsonDecode(res.body) as List)
              .map((j) => Incidente.fromJson(j))
              .where((i) => i.nivelRiesgo == 'ALTO')
              .toList();
          for (final inc in cercanos) {
            if (_alertasYaNotificadas.contains(inc.idIncidente)) continue;
            _alertasYaNotificadas.add(inc.idIncidente);
            _notifPlugin.show(
              id: inc.idIncidente,
              title: '⚠️ Alerta zona ALTA',
              body: '${inc.tipoIncidente} reportado a menos de $_radioAlertaKm km',
              notificationDetails: const NotificationDetails(
                android: AndroidNotificationDetails(
                  'zonas_peligrosas', 'Alertas de zonas peligrosas',
                  importance: Importance.high,
                  priority: Priority.high,
                ),
              ),
            );
          }
        }
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _alertTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final posInicial = _posicion != null
        ? LatLng(_posicion!.latitude, _posicion!.longitude)
        : const LatLng(-12.0464, -77.0428);

    final tipos = _incidentes.map((i) => i.tipoIncidente).toSet().toList();

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(),
                _buildFiltros(tipos),
                Expanded(
                  child: Stack(
                    children: [
                      GoogleMap(
                        initialCameraPosition:
                            CameraPosition(target: posInicial, zoom: 15),
                        onMapCreated: (c) => _mapController = c,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        markers: _marcadores,
                        circles: _zonasCercles,
                      ),
                      Positioned(top: 12, right: 12, child: _buildContador()),
                      Positioned(bottom: 12, left: 12, child: _buildLeyenda()),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () async {
          final resultado = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => ReporteScreen(
                posicionInicial: _posicion,
                onVerReportes: () => widget.onNavegarTab?.call(2),
              ),
            ),
          );
          if (resultado == true) _cargarIncidentes();
        },
        icon: const Icon(Icons.add),
        label: const Text('Reportar incidente'),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 16, 8),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AlertaZona',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                Text('Ciudad de México · Hoy',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ),
          CircleAvatar(
            radius: 19,
            backgroundColor: AppColors.surface,
            child: IconButton(
              icon: const Icon(Icons.person_outline, size: 20),
              onPressed: () => widget.onNavegarTab?.call(3),
              tooltip: 'Perfil',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltros(List<String> tipos) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _chipRiesgo('TODOS', 'Todos'),
          const SizedBox(width: 8),
          _chipRiesgo('ALTO', 'Alto'),
          const SizedBox(width: 8),
          _chipRiesgo('MEDIO', 'Medio'),
          const SizedBox(width: 8),
          _chipRiesgo('BAJO', 'Bajo'),
          const SizedBox(width: 8),
          PopupMenuButton<String?>(
            color: AppColors.surface,
            initialValue: _filtroTipo,
            onSelected: (v) => setState(() => _filtroTipo = v),
            itemBuilder: (_) => [
              const PopupMenuItem(value: null, child: Text('Todos los tipos')),
              ...tipos.map((t) => PopupMenuItem(value: t, child: Text(t))),
            ],
            child: Chip(
              label: Text(_filtroTipo ?? 'Tipo'),
              avatar: const Icon(Icons.filter_list, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipRiesgo(String valor, String label) {
    final activo = _filtroRiesgo == valor;
    return ChoiceChip(
      label: Text(label),
      selected: activo,
      onSelected: (_) => setState(() => _filtroRiesgo = valor),
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: activo ? Colors.white : AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildContador() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text('${_incidentesFiltrados.length}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const Text('incidentes',
              style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildLeyenda() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _leyendaFila(AppColors.riesgoAlto, 'Riesgo Alto'),
          const SizedBox(height: 4),
          _leyendaFila(AppColors.riesgoMedio, 'Riesgo Medio'),
          const SizedBox(height: 4),
          _leyendaFila(AppColors.riesgoBajo, 'Riesgo Bajo'),
        ],
      ),
    );
  }

  Widget _leyendaFila(Color color, String texto) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(texto, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}
