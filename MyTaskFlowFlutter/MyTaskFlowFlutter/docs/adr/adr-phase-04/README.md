# Architecture Decision Records — Phase 4: Backend Integration MVP

Decisiones arquitectónicas tomadas durante la integración de Firebase como backend real (FirebaseAuth + Cloud Firestore), reemplazando los datasources en memoria de las fases anteriores. Las decisiones de fases 0–3 siguen vigentes; este índice cubre únicamente las nuevas o las que amplían decisiones previas.

## Formato

```
Estado: Propuesto | Aceptado | Superado | Depreciado
```

Un ADR "Superado" enlaza al ADR que lo reemplaza.

---

## Índice

| ADR | Título | Estado | Tags |
|-----|--------|--------|------|
| [ADR-001](ADR-001-firebase-task-datasource-implements-repository.md) | `FirebaseTaskDatasource` implementa `TaskRepository` directamente | Aceptado | clean-architecture, datasource, repository, firebase |
| [ADR-002](ADR-002-remote-auth-datasource-exception-mapping.md) | `RemoteAuthDatasource` — mapeo de `FirebaseAuthException` a `Failure` jerárquico | Aceptado | auth, firebase, error-handling, pattern-matching |
| [ADR-003](ADR-003-task-model-firestore-timestamp-serialization.md) | `TaskModel.fromFirestore/toFirestore` — Timestamp ↔ DateTime como responsabilidad del modelo | Aceptado | data-layer, model, serialization, firestore, timestamp |
| [ADR-004](ADR-004-failure-mapper-funcion-pura-presentacion.md) | `mapFailureToMessage` — función pura centralizada para mensajes de UI | Aceptado | presentation, error-handling, pure-function, i18n |
| [ADR-005](ADR-005-network-info-interfaz-abstracta-conectividad.md) | `NetworkInfo` — interfaz abstracta para verificar conectividad | Aceptado | infrastructure, network, testability, connectivity-plus |
| [ADR-006](ADR-006-tests-riverpod-overrides-aislar-firebase.md) | Tests con Riverpod `overrides` para aislar Firebase en la suite de tests | Aceptado | testing, riverpod, firebase, isolation, overrides |
| [ADR-007](ADR-007-firestore-userid-campo-plano-vs-subcoleccion.md) | Tareas en colección plana con campo `userId` en lugar de sub-colecciones | Aceptado | firestore, data-model, scalability, security, multitenancy |

---

## Decisiones heredadas de fases anteriores

Las siguientes ADRs aplican sin cambios a Phase 4:

- [Clean Architecture en 3 capas](../adr-phase-01/ADR-001-clean-architecture.md) — `FirebaseTaskDatasource` y `RemoteAuthDatasource` viven en `data/datasources`; el dominio no los conoce.
- [Either<Failure, T> para errores](../adr-phase-01/ADR-004-either-functional-error-handling.md) — todos los métodos de los datasources Firebase retornan `Either`; nunca propagan excepciones al dominio.
- [Riverpod como gestor de estado](../adr-phase-01/ADR-002-riverpod-state-management.md) — los providers `authRepositoryProvider` y `taskRepositoryProvider` ahora resuelven a las implementaciones Firebase reales.
- [TaskModel — herencia sobre composición](../adr-phase-02/ADR-004-task-model-herencia-sobre-composicion.md) — `TaskModel extends Task` se mantiene; `fromFirestore` se añade como factory adicional al mismo modelo.
- [TDD first](../adr-phase-00/ADR-007-tdd-first-methodology.md) — los datasources Firebase se desarrollaron con fakes (`LocalAuthDatasource`, `InMemoryTaskDatasource`) para los tests de unidad antes de conectar Firebase real (ver ADR-006).

---

## Deudas técnicas identificadas en Phase 4

| Deuda | Descripción | ADR origen |
|---|---|---|
| `NetworkInfo` no integrado en datasources | `FirebaseTaskDatasource` no verifica conectividad antes de operar; los errores de red llegan como `FirebaseException` en lugar de `NetworkFailure` preventivo | ADR-005 |
| Sin `TaskRepositoryImpl` para offline-first | Cuando se añada caché local, `FirebaseTaskDatasource` deberá dejar de implementar `TaskRepository` directamente | ADR-001 |
| Firestore Security Rules no definidas | Sin rules, cualquier usuario autenticado puede leer o escribir tareas de otro usuario | ADR-007 |
| `searchTasks` en Firestore es in-memory | `FirebaseTaskDatasource.searchTasks` descarga todas las tareas del usuario y filtra en Dart — no escala | ADR-001 |
| Sin tests de integración con Firebase Emulator | Los smoke tests usan fakes; los bugs en `RemoteAuthDatasource` / `FirebaseTaskDatasource` solo se detectan manualmente | ADR-006 |
