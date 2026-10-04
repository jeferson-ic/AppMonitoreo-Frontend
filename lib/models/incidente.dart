class Incidente {
  final int idIncidente;
  final String tipoIncidente;
  final String descripcion;
  final double latitud;
  final double longitud;
  final String nivelRiesgo;
  final String fechaIncidente;
  final String estado;
  final int reportesCoincidentes;

  const Incidente({
    required this.idIncidente,
    required this.tipoIncidente,
    required this.descripcion,
    required this.latitud,
    required this.longitud,
    required this.nivelRiesgo,
    required this.fechaIncidente,
    required this.estado,
    this.reportesCoincidentes = 1,
  });

  factory Incidente.fromJson(Map<String, dynamic> j) => Incidente(
        idIncidente: j['idIncidente'] ?? 0,
        tipoIncidente: j['tipoIncidente'] ?? '',
        descripcion: j['descripcion'] ?? '',
        latitud: (j['latitud'] as num).toDouble(),
        longitud: (j['longitud'] as num).toDouble(),
        nivelRiesgo: j['nivelRiesgo'] ?? 'MEDIO',
        fechaIncidente: j['fechaIncidente'] ?? '',
        estado: j['estado'] ?? 'PENDIENTE',
        reportesCoincidentes:
            (j['reportesCoincidentes'] as num?)?.toInt() ?? 1,
      );
}
