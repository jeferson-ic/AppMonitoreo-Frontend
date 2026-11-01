import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/api_service.dart';
import '../services/eventos_app.dart';
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
  static const _otro = 'Otro';

  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _tipoOtroCtrl = TextEditingController();
  List<String> _tipos = [];
  String? _tipoSeleccionado;
  bool _loading = false;
  bool _loadingTipos = true;
  bool _errorTipos = false;

  Position? _posicion;
  // Punto que se envía: arranca en el GPS y el usuario puede ajustarlo.
  LatLng? _punto;
  GoogleMapController? _mapaCtrl;
  bool _buscandoUbicacion = false;
  String? _errorUbicacion;
  bool _permisoBloqueado = false;

  @override
  void initState() {
    super.initState();
    _cargarTipos();
    _posicion = widget.posicionInicial;
    final pos = _posicion;
    if (pos == null) {
      _obtenerUbicacion();
    } else {
      _punto = LatLng(pos.latitude, pos.longitude);
    }
  }

  bool get _hayCambios =>
      _tipoSeleccionado != null ||
      _descCtrl.text.trim().isNotEmpty ||
      _tipoOtroCtrl.text.trim().isNotEmpty;

  Future<void> _confirmarSalida() async {
    if (_loading) return;
    if (_hayCambios) {
      final salir = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('¿Descartar reporte?'),
          content: const Text('Se perderá la información que escribiste.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false), child: const Text('Seguir editando')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              child: const Text('Descartar'),
            ),
          ],
        ),
      );
      if (salir != true) return;
    }
    if (mounted) Navigator.pop(context);
  }

  void _mostrarMensaje(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _cargarTipos() async {
    setState(() {
      _loadingTipos = true;
      _errorTipos = false;
    });
    try {
      final token = await StorageService.getToken();
      final res = await ApiService.get('/incidentes/tipos', token: token);
      if (!mounted) return;
      if (res.statusCode == 200) {
        final lista = (ApiService.decodificar(res) as List).cast<String>();
        setState(() => _tipos = [...lista, _otro]);
      } else {
        setState(() => _errorTipos = true);
      }
    } catch (_) {
      if (mounted) setState(() => _errorTipos = true);
    } finally {
      if (mounted) setState(() => _loadingTipos = false);
    }
  }

  Future<void> _obtenerUbicacion() async {
    setState(() {
      _buscandoUbicacion = true;
      _errorUbicacion = null;
      _permisoBloqueado = false;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _errorUbicacion = 'Activa el GPS del teléfono';
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        _errorUbicacion = 'Permiso de ubicación denegado';
        _permisoBloqueado = perm == LocationPermission.deniedForever;
        return;
      }
      final pos = await Geolocator.getCurrentPosition()
          .timeout(const Duration(seconds: 15));
      _posicion = pos;
      _punto = LatLng(pos.latitude, pos.longitude);
      _mapaCtrl?.animateCamera(CameraUpdate.newLatLng(_punto!));
    } catch (_) {
      _errorUbicacion = 'No se pudo obtener la ubicación';
    } finally {
      if (mounted) setState(() => _buscandoUbicacion = false);
    }
  }

  String? get _tipoAEnviar {
    if (_tipoSeleccionado == null) return null;
    if (_tipoSeleccionado == _otro) {
      final texto = _tipoOtroCtrl.text.trim();
      return texto.isEmpty ? null : texto;
    }
    return _tipoSeleccionado;
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    final tipo = _tipoAEnviar;
    final pos = _punto;
    if (tipo == null) return;
    if (pos == null) {
      _mostrarMensaje('Necesitamos tu ubicación para registrar el reporte');
      return;
    }
    setState(() => _loading = true);
    try {
      final token = await StorageService.getToken();
      final res = await ApiService.post('/incidentes', {
        'tipoIncidente': tipo,
        'descripcion': _descCtrl.text.trim(),
        'latitud': pos.latitude,
        'longitud': pos.longitude,
      }, token: token);
      if (!mounted) return;
      if (res.statusCode == 201) {
        int idIncidente = 0;
        String estado = 'PENDIENTE';
        try {
          final data = ApiService.decodificar(res);
          idIncidente = data['idIncidente'] ?? 0;
          estado = data['estado'] ?? 'PENDIENTE';
        } catch (_) {}
        EventosApp.notificarIncidentes();
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ReporteExitoScreen(
              idIncidente: idIncidente,
              estado: estado,
              onVerReportes: widget.onVerReportes,
            ),
          ),
        );
      } else if (res.statusCode != 401) {
        _mostrarMensaje(
            ApiService.mensajeError(res, porDefecto: 'No se pudo enviar el reporte'));
      }
    } catch (e) {
      _mostrarMensaje(ApiService.mensajeExcepcion(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmarSalida();
      },
      child: Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    tooltip: 'Volver',
                    onPressed: _confirmarSalida,
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
                      LabeledField(label: 'Tipo de incidente', child: _campoTipo()),
                      if (_tipoSeleccionado == _otro) ...[
                        const SizedBox(height: 12),
                        LabeledField(
                          label: 'Especifica el tipo',
                          child: TextFormField(
                            controller: _tipoOtroCtrl,
                            decoration: const InputDecoration(hintText: 'Ej. Incendio'),
                            maxLength: 50,
                            textCapitalization: TextCapitalization.sentences,
                            validator: (v) => (_tipoSeleccionado == _otro &&
                                    (v == null || v.trim().isEmpty))
                                ? 'Requerido'
                                : null,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      LabeledField(
                        label: 'Descripción',
                        child: TextFormField(
                          controller: _descCtrl,
                          decoration: const InputDecoration(
                              hintText: 'Describe brevemente lo que está ocurriendo...'),
                          maxLines: 3,
                          maxLength: 280,
                          textCapitalization: TextCapitalization.sentences,
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      LabeledField(label: 'Ubicación', child: _campoUbicacion()),
                      const SizedBox(height: 24),
                      _loading
                          ? const Center(child: CircularProgressIndicator())
                          : SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                  onPressed: _punto == null ? null : _enviar,
                                  child: const Text('Enviar reporte')),
                            ),
                      if (_punto == null && !_loading) ...[
                        const SizedBox(height: 8),
                        Text(
                          _buscandoUbicacion
                              ? 'Esperando tu ubicación para habilitar el envío...'
                              : 'Necesitamos tu ubicación para poder enviar el reporte.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.warning, fontSize: 12),
                        ),
                      ],
                      const SizedBox(height: 10),
                      const Text(
                        'El nivel de riesgo se asigna según el tipo de incidente. '
                        'Tu reporte será revisado por el sistema de validación automática.',
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
      ),
    );
  }

  Widget _campoTipo() {
    if (_loadingTipos) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: LinearProgressIndicator(),
      );
    }
    if (_errorTipos) {
      return Row(
        children: [
          const Expanded(
            child: Text('No se pudieron cargar los tipos',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton.icon(
            onPressed: _cargarTipos,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Reintentar'),
          ),
        ],
      );
    }
    return DropdownButtonFormField<String>(
      initialValue: _tipoSeleccionado,
      decoration: const InputDecoration(),
      hint: const Text('Selecciona un tipo'),
      dropdownColor: AppColors.surface,
      items: _tipos.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
      onChanged: (v) => setState(() => _tipoSeleccionado = v),
      validator: (v) => v == null ? 'Selecciona un tipo' : null,
    );
  }

  Widget _campoUbicacion() {
    final pos = _punto;
    if (pos != null) return _mapaUbicacion(pos);
    final String texto;
    if (_buscandoUbicacion) {
      texto = 'Obteniendo ubicación...';
    } else {
      texto = _errorUbicacion ?? 'Ubicación no disponible';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      constraints: const BoxConstraints(minHeight: 50),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _buscandoUbicacion ? AppColors.border : AppColors.danger),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_off, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(child: Text(texto, overflow: TextOverflow.ellipsis)),
          if (_buscandoUbicacion)
            const SizedBox(
                width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
          else if (_permisoBloqueado)
            TextButton(
                onPressed: () async {
                  await Geolocator.openAppSettings();
                },
                child: const Text('Ajustes'))
          else
            TextButton(onPressed: _obtenerUbicacion, child: const Text('Reintentar')),
        ],
      ),
    );
  }

  Widget _mapaUbicacion(LatLng pos) {
    final gps = _posicion;
    final ajustado = gps != null &&
        (gps.latitude != pos.latitude || gps.longitude != pos.longitude);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 180,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: pos, zoom: 17),
              onMapCreated: (c) => _mapaCtrl = c,
              // El mapa recibe los gestos para poder moverlo dentro del scroll.
              gestureRecognizers: {
                Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
              },
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              myLocationButtonEnabled: false,
              onTap: (p) => setState(() => _punto = p),
              markers: {
                Marker(
                  markerId: const MarkerId('reporte'),
                  position: pos,
                  draggable: true,
                  onDragEnd: (p) => setState(() => _punto = p),
                ),
              },
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(ajustado ? Icons.edit_location_alt : Icons.my_location,
                size: 14, color: AppColors.textMuted),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                ajustado
                    ? 'Ubicación ajustada manualmente'
                    : 'Toca el mapa o arrastra el pin para ajustar',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ),
            if (ajustado)
              TextButton(
                onPressed: () {
                  final p = LatLng(gps.latitude, gps.longitude);
                  setState(() => _punto = p);
                  _mapaCtrl?.animateCamera(CameraUpdate.newLatLng(p));
                },
                child: const Text('Usar GPS'),
              ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _tipoOtroCtrl.dispose();
    _mapaCtrl?.dispose();
    super.dispose();
  }
}
