# ADR-008: Firebase como plataforma de backend

- **Estado**: Aceptado (pendiente de activación en Phase 3)
- **Fecha**: 2026-06-01
- **Fase**: 0 — Fundación (activación: Phase 3)

## Contexto

La app necesita en el mediano plazo:
- **Autenticación real**: email/password, y potencialmente Google Sign-In.
- **Persistencia remota**: las tareas deben sincronizarse entre dispositivos y sobrevivir a reinicios.
- **Tiempo real** (opcional): actualizaciones de tareas reflejadas inmediatamente en todos los clientes.

Se evaluaron las siguientes opciones de backend:

| Opción | Evaluación |
|--------|------------|
| **REST API propio** (Node, Django, etc.) | Control total, pero requiere infraestructura, autenticación, base de datos y deploy propios. Costo de mantenimiento alto para un proyecto en fase inicial. |
| **Supabase** | Alternativa open-source a Firebase con PostgreSQL. Menor lock-in, pero la integración con Flutter es menos madura que Firebase. |
| **Appwrite** | Self-hosted, control de datos. Requiere infra propia. |
| **Firebase (Auth + Firestore)** | **Seleccionado.** SDKs oficiales de Flutter, ampliamente documentado, soporta real-time out-of-the-box, tier gratuito suficiente para MVP. |

## Decisión

Se usa **Firebase** con los siguientes servicios:

| Servicio | Uso en el proyecto |
|----------|--------------------|
| **Firebase Auth** | Autenticación con email/password. Reemplaza `LocalAuthDatasource` en Phase 3. |
| **Cloud Firestore** | Persistencia de tareas en tiempo real. Reemplaza `InMemoryTaskDatasource` en Phase 3. |
| **Firebase Core** | Inicialización compartida. |

Servicios de Firebase **no previstos** en el roadmap actual:
- Firebase Storage (no hay adjuntos de archivos planificados).
- Firebase Crashlytics / Analytics (se evaluarán en fases de producción).
- Firebase Cloud Messaging (notificaciones push, no planificadas en el roadmap inicial).

La configuración (`google-services.json`, `GoogleService-Info.plist`) **no se commitea** al repositorio. Se gestionará via variables de entorno en CI/CD.

## Consecuencias

**Positivas:**
- La integración Flutter ↔ Firebase es la más madura del ecosistema (FlutterFire plugins oficiales).
- Autenticación + persistencia + tiempo real sin mantener backend propio.
- La arquitectura in-memory de Phases 1-2 hace que el swap a Firebase sea solo un cambio de datasource (ver ADR-006).
- Firestore soporta queries offline nativamente, útil para uso sin conexión.

**Negativas / trade-offs:**
- **Vendor lock-in**: migrar fuera de Firebase en el futuro requiere reemplazar datasources y el modelo de datos.
- El modelo de precios de Firestore escala por lecturas/escrituras/documentos, no por almacenamiento. Queries ineficientes pueden generar costos inesperados.
- Firestore no es una base de datos relacional; las queries complejas (joins, agregaciones) requieren modelado de datos denormalizado y son más difíciles que en SQL.
- **Regla de seguridad de Firestore** (Firestore Security Rules) es una capa adicional que debe mantenerse sincronizada con la lógica de la app.
