const _meses = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

/// Convierte la fecha que envía el backend a la hora local del teléfono.
/// El backend envía la hora de Perú sin zona horaria (yyyy-MM-ddTHH:mm:ss),
/// que se usa tal cual. Si alguna vez llega con zona (Z o -05:00), se
/// convierte a la hora local para no mostrarla adelantada.
DateTime? leerFecha(String raw) {
  final fecha = DateTime.tryParse(raw);
  if (fecha == null) return null;
  return fecha.isUtc ? fecha.toLocal() : fecha;
}

String formatearFechaHora(String raw) {
  final fecha = leerFecha(raw);
  if (fecha == null) return raw;
  final dia = fecha.day.toString();
  final mes = _meses[fecha.month - 1];
  final hora = fecha.hour.toString().padLeft(2, '0');
  final min = fecha.minute.toString().padLeft(2, '0');
  return '$dia $mes ${fecha.year}, $hora:$min';
}

String formatearFecha(String raw) {
  final fecha = leerFecha(raw);
  if (fecha == null) return raw;
  final dia = fecha.day.toString();
  final mes = _meses[fecha.month - 1];
  return '$dia $mes ${fecha.year}';
}

bool esHoy(String raw) {
  final fecha = leerFecha(raw);
  if (fecha == null) return false;
  final ahora = DateTime.now();
  return fecha.year == ahora.year && fecha.month == ahora.month && fecha.day == ahora.day;
}
