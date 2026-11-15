import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/incidente.dart';
import 'package:frontend/utils/fecha_utils.dart';

Incidente _incidente(String estado) => Incidente.fromJson({
      'idIncidente': 7,
      'tipoIncidente': 'Robo',
      'descripcion': 'Prueba',
      'latitud': -12.05,
      'longitud': -77.04,
      'nivelRiesgo': 'MEDIO',
      'fechaIncidente': '2026-11-13T22:26:00',
      'estado': estado,
    });

void main() {
  group('Fechas', () {
    test('La fecha sin zona del backend (hora de Perú) se muestra tal cual', () {
      expect(formatearFechaHora('2026-11-13T22:26:00'), '13 nov 2026, 22:26');
      expect(formatearFecha('2026-11-13T22:26:00'), '13 nov 2026');
    });

    test('Una fecha con zona horaria se convierte a la hora local', () {
      final fecha = leerFecha('2026-11-14T03:26:00Z')!;
      expect(fecha.isUtc, isFalse);
      expect(fecha, DateTime.utc(2026, 11, 14, 3, 26).toLocal());
    });

    test('Un texto que no es fecha se devuelve sin cambios', () {
      expect(formatearFechaHora('sin fecha'), 'sin fecha');
      expect(esHoy('sin fecha'), isFalse);
    });
  });

  group('Estado del incidente', () {
    test('Un incidente validado se ve con opacidad completa', () {
      final inc = _incidente('VALIDADO');
      expect(inc.estaValidado, isTrue);
      expect(inc.opacidadMarcador, 1.0);
    });

    test('Un incidente pendiente se ve semitransparente (sin confirmar)', () {
      final inc = _incidente('PENDIENTE');
      expect(inc.estaValidado, isFalse);
      expect(inc.opacidadMarcador, lessThan(1.0));
    });
  });
}
