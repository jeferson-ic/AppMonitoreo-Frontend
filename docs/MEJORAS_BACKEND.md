# Mejoras pendientes en el backend (según RF/RNF del proyecto)

Contexto: se revisó el frontend contra `API_REFERENCE.md` y contra la tabla de
Requerimientos Funcionales (RF), No Funcionales (RNF) e Historias de Usuario
(HU) de la constitución del proyecto. La mayoría de los gaps encontrados eran
del lado del frontend (ya corregidos ahí). Esto es lo que queda pendiente del
lado del backend.

---

## 1. RNF03 — Comunicación por HTTPS (Alta)

> "La comunicación entre la app y el servidor debe ser mediante HTTPS."

Hoy el backend se sirve en local por HTTP plano (`http://localhost:8080`), lo
cual está bien para desarrollo. Pero para cualquier ambiente que no sea el
emulador local (demo, sustentación, dispositivos reales), el backend debe
exponerse detrás de HTTPS (certificado TLS — Let's Encrypt, o el que ofrezca
el proveedor de hosting).

**Acción:** cuando tengan una URL de despliegue (staging/producción), que sea
`https://...` y avísenme para actualizar la base URL del frontend. En el
frontend ya configuré que el build de **release** de Android bloquee tráfico
HTTP por defecto (solo el build debug permite HTTP hacia `10.0.2.2`/
`localhost` para desarrollo local) — así que un build de producción fallará
directamente si la URL sigue en HTTP, en vez de exponer datos sin cifrar.

## 2. RF04 — Push real de Firebase (Alta)

> "El sistema debe enviar una alerta cuando el usuario ingrese a una zona de
> riesgo alto."

El propio `API_REFERENCE.md` ya lo señala: *"el envío de push real (Firebase)
todavía no está conectado en el backend (falta credencial de servicio)"*. Hoy
la app cubre esto con **polling desde el cliente** llamando a
`GET /alertas/verificar` cada vez que cambia la ubicación del usuario — esto
solo funciona mientras la app está abierta en primer plano.

**Acción:** configurar la credencial de servicio de Firebase (service account
JSON) en el backend y, cuando se detecte que un usuario con token FCM
registrado (`PUT /usuarios/token-fcm`, ya implementado) entra en radio de un
incidente `ALTO`, enviar una notificación push real vía Firebase Admin SDK.
Esto permite alertar aunque la app esté cerrada o en background — clave para
que RF04/HU05 funcione de forma confiable, no solo mientras el usuario tiene
la app abierta.

## 3. RNF01 y RNF07 — Confirmar tiempos de respuesta (Media)

> RNF01: "El tiempo de respuesta del sistema no debe superar los 3 segundos
> en condiciones normales."
> RNF07: "El algoritmo de validación automática debe evaluar cada reporte en
> menos de 5 segundos, con un radio de 150 metros y una ventana de 24 horas."

No hay forma de verificar esto desde el frontend — son cifras de rendimiento
del servidor. Ya que el backend registra eventos internos (RF07, endpoint
`GET /admin/eventos`), sugiero:

- Medir/loggear cuánto tarda el algoritmo de auto-validación (RF10) en cada
  ejecución, y registrar un evento `WARNING` si supera los 5 segundos.
- Confirmar informalmente (con una prueba de carga simple o revisando logs)
  que los endpoints más usados (`/incidentes`, `/incidentes/zonas-riesgo`,
  `/alertas/verificar`) responden por debajo de 3 segundos en condiciones
  normales.

**Acción:** no es necesario un endpoint nuevo, solo confirmar/instrumentar
que se cumplen estos umbrales, ya que son parte de la sustentación (RNF05
habla de disponibilidad durante esa semana).

## 4. RNF02 — Confirmar cifrado de contraseñas (Media)

> "Las contraseñas deben almacenarse cifradas (BCrypt)."

El contrato de la API (`POST /auth/login` / `POST /auth/register`) no permite
verificar esto desde afuera — es un detalle interno de implementación.

**Acción:** solo pido confirmación de que el almacenamiento de `contrasena`
en la base de datos usa BCrypt (o equivalente) y no texto plano, para poder
tacharlo como cumplido en la checklist de RNF.

---

## Lo que NO requiere cambios en el backend

Todo lo demás del `API_REFERENCE.md` (auth, incidentes, alertas, admin,
métricas, eventos) ya está completo y bien documentado — los demás gaps que
encontramos (botón "Rechazar" llamando al endpoint equivocado, panel de
métricas no usando `/admin/metricas`, filtro de fecha faltante, etc.) eran
errores de consumo en el frontend y ya se corrigieron ahí. No hace falta
tocar el backend para esos casos.
