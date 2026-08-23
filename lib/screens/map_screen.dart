import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/incidente.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'reporte_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  Position? _posicion;
  Set<Marker> _marcadores = {};
  Set<Circle> _zonasCercles = {};
  Timer? _alertTimer;
  final _notifPlugin = FlutterLocalNotificationsPlugin();
  final Set<int> _alertasYaNotificadas = {};

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
        setState(() {
          _marcadores = lista.map(_incidenteAMarcador).toSet();
        });
        await _cargarZonasRiesgo();
      }
    } catch (_) {}
  }

  Marker _incidenteAMarcador(Incidente inc) {
    final color = switch (inc.nivelRiesgo) {
      'ALTO' => BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      'MEDIO' =>
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      _ => BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
    };
    return Marker(
      markerId: MarkerId(inc.idIncidente.toString()),
      position: LatLng(inc.latitud, inc.longitud),
      icon: color,
      infoWindow: InfoWindow(
          title: inc.tipoIncidente,
          snippet: '${inc.nivelRiesgo} · ${inc.estado}'),
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

    return Scaffold(
      body: GoogleMap(
        initialCameraPosition: CameraPosition(target: posInicial, zoom: 15),
        onMapCreated: (c) => _mapController = c,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        markers: _marcadores,
        circles: _zonasCercles,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final resultado = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
                builder: (_) => ReporteScreen(posicionInicial: _posicion)),
          );
          if (resultado == true) _cargarIncidentes();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
