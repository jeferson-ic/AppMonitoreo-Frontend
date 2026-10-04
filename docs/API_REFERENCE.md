# API Reference — AppMonitoreo Backend

Base URL local: `http://localhost:8080`
(Android emulator: usar `http://10.0.2.2:8080` en vez de `localhost`)

Todas las rutas devuelven/reciben JSON. Excepto `/auth/**`, **todas** requieren
el header:

```
Authorization: Bearer <token>
```

El token se obtiene en `/auth/login` (ver abajo) y ya lo tienes operativo
(login/token/storage). Las rutas bajo `/admin/**` además requieren que el
usuario del token tenga `rol = ADMIN`.

Formato de error estándar (validación de campos, 400):
```json
{ "error": "Datos inválidos", "detalles": { "campo": "mensaje" } }
```
Error genérico no controlado (500):
```json
{ "error": "Error interno del servidor" }
```

---

## Pantalla: Login / Registro ✅ (ya operativo)

### POST /auth/register
Auth: no requiere token.

Request:
```json
{
  "nombre": "Juan Pérez",
  "correo": "juan@correo.com",
  "contrasena": "123456",
  "telefono": "987654321"
}
```
- `contrasena`: mínimo 6 caracteres.
- `telefono`: opcional.

Respuestas:
- `201` → `{ "mensaje": "Usuario registrado correctamente" }`
- `409` → `{ "error": "El correo ya está registrado" }`

### POST /auth/login
Auth: no requiere token.

Request:
```json
{ "correo": "juan@correo.com", "contrasena": "123456" }
```

Respuestas:
- `200`:
```json
{
  "token": "eyJhbGciOi...",
  "correo": "juan@correo.com",
  "nombre": "Juan Pérez",
  "rol": "USUARIO"
}
```
- `401` → `{ "error": "Credenciales incorrectas" }`

---

## Pantalla: Reportar incidente

### POST /incidentes
Auth: Bearer token (cualquier usuario autenticado).

Request:
```json
{
  "tipoIncidente": "Robo",
  "descripcion": "Robo de celular a mano armada en la esquina",
  "latitud": -12.0464000,
  "longitud": -77.0428000,
  "fechaIncidente": "2026-09-22T14:30:00"
}
```
- `tipoIncidente`: obligatorio, uno de los valores de `GET /incidentes/tipos` (si mandas otro, se le asigna riesgo `MEDIO` por defecto).
- `descripcion`: obligatorio.
- `latitud`/`longitud`: obligatorios, decimales (rango -90..90 / -180..180).
- `fechaIncidente`: **opcional**, ISO-8601 `yyyy-MM-ddTHH:mm:ss`. No puede ser futura. Si se omite, se usa la hora del servidor.

Respuesta `201` (el objeto `Incidente` guardado; `estado` puede llegar ya como
`"VALIDADO"` si el sistema lo auto-validó al crearlo):
```json
{
  "idIncidente": 15,
  "usuario": { "idUsuario": 3, "nombre": "Juan Pérez", "correo": "juan@correo.com", ... },
  "tipoIncidente": "Robo",
  "descripcion": "Robo de celular a mano armada en la esquina",
  "latitud": -12.0464000,
  "longitud": -77.0428000,
  "nivelRiesgo": "MEDIO",
  "fechaIncidente": "2026-09-22T14:30:00",
  "estado": "PENDIENTE"
}
```

### GET /incidentes/tipos
Auth: Bearer token. Lista de tipos válidos para el picker/dropdown del formulario.

Respuesta `200`:
```json
["Accidente","Acoso","Asalto","Robo","Robo a mano armada","Secuestro","Sospechoso","Vandalismo"]
```

---

## Pantalla: Mapa interactivo / zonas de riesgo

### GET /incidentes
Auth: Bearer token. Lista general con filtros opcionales (RF09).

Query params (todos opcionales):
- `tipo` — igual a un valor de `/incidentes/tipos`
- `nivelRiesgo` — `ALTO` | `MEDIO` | `BAJO`
- `fechaDesde` — `yyyy-MM-dd`
- `fechaHasta` — `yyyy-MM-dd`

Ejemplo: `GET /incidentes?nivelRiesgo=ALTO&fechaDesde=2026-09-01`

Respuesta `200`: array de `Incidente` (mismo shape que arriba).

### GET /incidentes/cercanos
Auth: Bearer token. Para centrar el mapa en la ubicación del usuario.

Query params: `lat` (double, obligatorio), `lng` (double, obligatorio), `radioKm` (double, default `1.0`).

Respuesta `200`: array de `Incidente`.

### GET /incidentes/zonas-riesgo
Auth: Bearer token. Puntos agregados (heatmap) — útil para pintar el mapa sin cargar cada incidente individual.

Respuesta `200`:
```json
[
  { "celda_lat": -12.046, "celda_lng": -77.043, "cantidad": 7 },
  { "celda_lat": -12.050, "celda_lng": -77.030, "cantidad": 3 }
]
```

---

## Pantalla: Mi historial de reportes

### GET /incidentes/mis-reportes
Auth: Bearer token. Devuelve solo los incidentes del usuario autenticado (incluye `PENDIENTE`, `VALIDADO`, `RECHAZADO`; excluye `ELIMINADO`).

Respuesta `200`: array de `Incidente`.

---

## Pantalla: Alertas por proximidad (RF04)

### GET /alertas/verificar
Auth: Bearer token. Llamar periódicamente (p. ej. cada vez que cambie la ubicación GPS, o cada pocos segundos) con la posición actual del usuario, para saber si debe mostrarse una alerta local.

Query params: `lat` (double, obligatorio), `lng` (double, obligatorio), `radioMetros` (double, default `300`).

Respuesta `200`:
```json
{
  "enZonaDeRiesgo": true,
  "incidentesCercanos": 2,
  "detalle": [ /* array de Incidente con nivelRiesgo=ALTO */ ]
}
```
Si `enZonaDeRiesgo` es `true`, mostrar notificación/banner local en la app.

> Nota: el envío de push real (Firebase) todavía no está conectado en el backend
> (falta credencial de servicio). Por eso este endpoint es la vía confiable por
> ahora: polling desde el cliente. Cuando se integre FCM, este mismo endpoint
> seguirá funcionando igual.

### PUT /usuarios/token-fcm
Auth: Bearer token. Llamar una vez que la app tenga el token FCM del dispositivo (para dejarlo listo cuando se active el push).

Request:
```json
{ "tokenFcm": "token-del-dispositivo" }
```
Respuesta `200` → `{ "mensaje": "Token FCM actualizado" }`

---

## Pantallas de Administrador

### GET /admin/incidentes/pendientes
Auth: Bearer token, rol `ADMIN`. Respuesta `200`: array de `Incidente` con `estado = PENDIENTE`.

### PUT /admin/incidentes/{id}/validar
Auth: rol `ADMIN`. Sin body. Respuesta `200` → `{ "mensaje": "Incidente {id} marcado como VALIDADO" }`

### PUT /admin/incidentes/{id}/rechazar
Auth: rol `ADMIN`. Sin body. Respuesta `200` → `{ "mensaje": "Incidente {id} marcado como RECHAZADO" }`

### PUT /admin/incidentes/{id}/eliminar
Auth: rol `ADMIN`. Sin body (borrado lógico). Respuesta `200` → `{ "mensaje": "Incidente {id} marcado como ELIMINADO" }`

### GET /admin/metricas
Auth: rol `ADMIN`. Panel de métricas (RF08).

Respuesta `200`:
```json
{
  "totalIncidentes": 42,
  "porEstado": { "PENDIENTE": 5, "VALIDADO": 30, "RECHAZADO": 4, "ELIMINADO": 3 },
  "validacionesAutomaticas": 18,
  "validacionesManuales": 12,
  "porcentajeValidacionAutomatica": 60.0,
  "totalUsuarios": 120,
  "usuariosActivos": 115,
  "totalAlertasRiesgoAlto": 9,
  "zonasMasRiesgosas": [
    { "celda_lat": -12.046, "celda_lng": -77.043, "cantidad": 7 }
  ]
}
```

### GET /admin/eventos
Auth: rol `ADMIN`. Log interno del sistema (RF07).

Query params opcionales: `tipo` (`INFO` | `WARNING` | `ERROR`), `limite` (default `100`, máx `500`).

Respuesta `200`: array de eventos:
```json
[
  {
    "idEvento": 101,
    "tipo": "WARNING",
    "componente": "AUTH",
    "mensaje": "Intento de login fallido para: juan@correo.com",
    "usuario": null,
    "fechaEvento": "2026-09-22T10:15:00"
  }
]
```

---

## Cómo usar esto pantalla por pantalla

1. Cuando ajustes una screen nueva en el frontend, dime cuál es (o pégame la
   sección correspondiente de este archivo) y te confirmo el/los endpoint(s)
   exactos + cualquier detalle que aplique a esa pantalla en particular.
2. Este archivo vive en `docs/API_REFERENCE.md` de este repo — cópialo (o un
   fragmento) al proyecto frontend, o pégalo directamente en la sesión de
   Claude Code que lleva el frontend, como contexto para esa pantalla.
3. Si cambio algo del backend (nuevo campo, nueva validación, endpoint nuevo),
   actualizo este archivo en el mismo commit para que no se desalinee.
