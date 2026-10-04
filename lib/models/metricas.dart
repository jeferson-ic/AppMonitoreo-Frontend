class ZonaRiesgo {
  final double celdaLat;
  final double celdaLng;
  final int cantidad;

  const ZonaRiesgo({
    required this.celdaLat,
    required this.celdaLng,
    required this.cantidad,
  });

  factory ZonaRiesgo.fromJson(Map<String, dynamic> j) => ZonaRiesgo(
        celdaLat: (j['celda_lat'] as num).toDouble(),
        celdaLng: (j['celda_lng'] as num).toDouble(),
        cantidad: (j['cantidad'] as num).toInt(),
      );
}

class Metricas {
  final int totalIncidentes;
  final Map<String, int> porEstado;
  final int validacionesAutomaticas;
  final int validacionesManuales;
  final double porcentajeValidacionAutomatica;
  final int totalUsuarios;
  final int usuariosActivos;
  final int totalAlertasRiesgoAlto;
  final List<ZonaRiesgo> zonasMasRiesgosas;

  const Metricas({
    required this.totalIncidentes,
    required this.porEstado,
    required this.validacionesAutomaticas,
    required this.validacionesManuales,
    required this.porcentajeValidacionAutomatica,
    required this.totalUsuarios,
    required this.usuariosActivos,
    required this.totalAlertasRiesgoAlto,
    required this.zonasMasRiesgosas,
  });

  factory Metricas.fromJson(Map<String, dynamic> j) => Metricas(
        totalIncidentes: (j['totalIncidentes'] as num?)?.toInt() ?? 0,
        porEstado: (j['porEstado'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, (v as num).toInt())) ??
            const {},
        validacionesAutomaticas:
            (j['validacionesAutomaticas'] as num?)?.toInt() ?? 0,
        validacionesManuales: (j['validacionesManuales'] as num?)?.toInt() ?? 0,
        porcentajeValidacionAutomatica:
            (j['porcentajeValidacionAutomatica'] as num?)?.toDouble() ?? 0.0,
        totalUsuarios: (j['totalUsuarios'] as num?)?.toInt() ?? 0,
        usuariosActivos: (j['usuariosActivos'] as num?)?.toInt() ?? 0,
        totalAlertasRiesgoAlto: (j['totalAlertasRiesgoAlto'] as num?)?.toInt() ?? 0,
        zonasMasRiesgosas: (j['zonasMasRiesgosas'] as List<dynamic>? ?? [])
            .map((z) => ZonaRiesgo.fromJson(z as Map<String, dynamic>))
            .toList(),
      );
}
