import 'package:flutter/foundation.dart';

/// Avisa a las pantallas que mantienen estado (mapa, búsqueda, historial)
/// que los incidentes cambiaron y deben recargarse.
class EventosApp {
  static final incidentesCambiaron = ValueNotifier<int>(0);

  static void notificarIncidentes() => incidentesCambiaron.value++;
}
