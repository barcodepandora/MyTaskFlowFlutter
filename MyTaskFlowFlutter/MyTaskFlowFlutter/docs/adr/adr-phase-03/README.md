# Architecture Decision Records — Phase 3: Dashboard & Search/Filter MVP

Decisiones arquitectónicas tomadas durante la implementación del Dashboard de productividad y el sistema de búsqueda/filtrado de tareas (Phase 3). Las decisiones de fases anteriores siguen vigentes; este índice cubre únicamente las nuevas o las que amplían decisiones previas.

## Formato

```
Estado: Propuesto | Aceptado | Superado | Depreciado
```

Un ADR "Superado" enlaza al ADR que lo reemplaza.

---

## Índice

| ADR | Título | Estado | Tags |
|-----|--------|--------|------|
| [ADR-001](ADR-001-taskstats-entidad-dominio-fromlist.md) | TaskStats como entidad de dominio puro con factory `fromList()` | Aceptado | domain, entity, statistics, pure-function |
| [ADR-002](ADR-002-searchnotifier-filtrado-local-sincrono.md) | SearchNotifier — filtrado local sincrónico en lugar de async use case | Aceptado | search, riverpod, ux, performance, sync |
| [ADR-003](ADR-003-taskfilter-equatable-isoverdue.md) | TaskFilter extendido con Equatable e `isOverdue` | Aceptado | domain, filter, equatable, value-object |
| [ADR-004](ADR-004-statefulshellroute-bottomnav.md) | `StatefulShellRoute.indexedStack` para navegación con BottomNavigationBar | Aceptado | navigation, gorouter, shell-route, state-preservation |
| [ADR-005](ADR-005-dashboardnotifier-independiente-de-tasksnotifier.md) | DashboardNotifier accede al repositorio directamente, sin depender de TasksNotifier | Aceptado | state-management, riverpod, single-responsibility, coupling |

---

## Decisiones heredadas de fases anteriores

Las siguientes ADRs de Phase 0/1/2 aplican sin cambios a Phase 3:

- [Clean Architecture en 3 capas](../adr-phase-01/ADR-001-clean-architecture.md) — las features `dashboard/`, `shell/` y `profile/` siguen la misma estructura `domain/data/presentation`.
- [Riverpod como gestor de estado](../adr-phase-01/ADR-002-riverpod-state-management.md) — `DashboardNotifier` y `SearchNotifier` son `StateNotifier` inyectados via provider, igual que `TasksNotifier` y `AuthNotifier`.
- [GoRouter como router](../adr-phase-00/ADR-003-gorouter-navigation.md) — `StatefulShellRoute` es una capacidad nativa de GoRouter; no requiere dependencia adicional (ver ADR-004).
- [Either<Failure, T> para errores](../adr-phase-01/ADR-004-either-functional-error-handling.md) — `GetDashboardStatsUseCase` y `GetRecentActivityUseCase` retornan `Either<Failure, T>` con el patrón `isLeft()` heredado de [Phase 2 — ADR-006](../adr-phase-02/ADR-006-dartz-interop-hide-task-isleft-pattern.md).
- [Equatable para igualdad](../adr-phase-01/ADR-007-equatable-entity-equality.md) — `TaskStats`, `DashboardState`, `SearchState` y (nuevo) `TaskFilter` adoptan Equatable de forma consistente.
- [InMemoryTaskDatasource como placeholder](../adr-phase-02/ADR-003-in-memory-task-datasource-placeholder.md) — extendido en Phase 3 para soportar `isOverdue` y 6 seed tasks, sigue siendo temporal hasta Phase 4.

---

## Deudas técnicas identificadas en Phase 3

Las siguientes decisiones generan deuda técnica documentada a resolver en Phase 4:

| Deuda | Descripción | ADR origen |
|---|---|---|
| Doble lectura al repositorio en Dashboard | `GetDashboardStatsUseCase` y `GetRecentActivityUseCase` llaman a `getAllTasks()` por separado | ADR-005 |
| Filtrado local no escala a Firestore | `SearchNotifier._applyFilters()` opera in-memory; con Firestore requiere queries del lado del servidor | ADR-002 |
| Dashboard desactualizado tras mutaciones | `DashboardNotifier` no reacciona automáticamente a cambios CRUD; depende de `refresh()` manual | ADR-005 |
| Redirect post-login sin preservar destino original | El guard redirige siempre a `/home`, perdiendo el deeplink original si el usuario no estaba autenticado | ADR-004 |
