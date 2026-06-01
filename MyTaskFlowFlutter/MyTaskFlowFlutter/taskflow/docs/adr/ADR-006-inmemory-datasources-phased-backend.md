# ADR-006: Datasources in-memory en Phases 1-2, Firebase en Phase 3+

- **Estado**: Aceptado
- **Fecha**: 2026-06-01
- **Fase**: 0 — Fundación

## Contexto

Firebase (Auth + Firestore) es el backend objetivo del proyecto. Sin embargo, configurar Firebase desde la Phase 1 introduce complejidades que no son el foco de las primeras fases:
- Credenciales de servicio (google-services.json, GoogleService-Info.plist) que no deben ir a git.
- Dependencia de red y estado de Firebase en los tests.
- Latencia real que dificulta verificar comportamiento de estados de carga en desarrollo.

## Decisión

Las **Phases 1 y 2 usan datasources in-memory** que implementan exactamente las mismas interfaces que usarán los datasources de Firebase:

```
Phase 1-2                         Phase 3+
─────────────────────────         ─────────────────────────────────
LocalAuthDatasource               FirebaseAuthDatasource
  └─ credenciales hardcoded         └─ firebase_auth SDK

InMemoryTaskDatasource            FirestoreTaskDatasource
  └─ List<TaskModel> en RAM         └─ cloud_firestore SDK
```

El **contrato del repositorio** (domain layer) no cambia entre phases. Los providers de Riverpod en `data/providers/` son el único lugar que cambia al hacer el swap:

```dart
// Phase 2
final taskRepositoryProvider = Provider((_) =>
  TaskRepositoryImpl(InMemoryTaskDatasource()));

// Phase 3 (solo este archivo cambia)
final taskRepositoryProvider = Provider((ref) =>
  TaskRepositoryImpl(FirestoreTaskDatasource(ref.watch(firestoreProvider))));
```

Firebase ya está importado en `pubspec.yaml` para evitar conflictos de versión al integrarlo, pero no está inicializado ni usado.

## Consecuencias

**Positivas:**
- Las Phases 1 y 2 no requieren configuración de Firebase; cualquier desarrollador puede correr la app sin credenciales.
- Los tests unitarios y de widget no necesitan mocks de Firebase SDK.
- El comportamiento de la app es 100% determinista en desarrollo (sin latencia de red, sin cuotas).
- La migración a Firebase es un cambio de una sola capa (data), verificable con los mismos tests de dominio.

**Negativas / trade-offs:**
- Los datos in-memory se pierden al reiniciar la app. Esto es aceptable para desarrollo pero debe comunicarse a cualquier evaluador de la Phase 2.
- Los 3 tasks de semilla (`InMemoryTaskDatasource`) son datos de prueba; deben eliminarse o hacerse configurables antes de producción.
- Firebase no está probado hasta la Phase 3. Si el contrato del SDK no encaja perfectamente con la interfaz diseñada, habrá que ajustar la interfaz en ese momento.
