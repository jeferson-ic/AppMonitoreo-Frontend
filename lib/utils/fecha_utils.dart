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

String formatearFechaHora(String raw) {
  final fecha = DateTime.tryParse(raw);
  if (fecha == null) return raw;
  final dia = fecha.day.toString();
  final mes = _meses[fecha.month - 1];
  final hora = fecha.hour.toString().padLeft(2, '0');
  final min = fecha.minute.toString().padLeft(2, '0');
  return '$dia $mes ${fecha.year}, $hora:$min';
}

String formatearFecha(String raw) {
  final fecha = DateTime.tryParse(raw);
  if (fecha == null) return raw;
  final dia = fecha.day.toString();
  final mes = _meses[fecha.month - 1];
  return '$dia $mes ${fecha.year}';
}

bool esHoy(String raw) {
  final fecha = DateTime.tryParse(raw);
  if (fecha == null) return false;
  final ahora = DateTime.now();
  return fecha.year == ahora.year && fecha.month == ahora.month && fecha.day == ahora.day;
}
