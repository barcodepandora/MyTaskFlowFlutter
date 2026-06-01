# ADR-005: DashboardNotifier accede al repositorio directamente, sin depender de TasksNotifier

**Estado:** Aceptado  
**Fecha:** 2026-06-01  
**Fase:** Phase 3 — Dashboard & Search/Filter MVP  
**Tags:** state-management, riverpod, single-responsibility, data-independence, coupling

---

## Contexto

`DashboardPage` necesita dos conjuntos de datos para renderizarse:

1. `TaskStats` — contadores derivados de la lista completa de tareas.
2. `List<Task>` — las últimas N tareas modificadas (actividad reciente).

Ambos se derivan de la misma fuente: `TaskRepository.getAllTasks()`. Ya existe `TasksNotifier` que también llama a `TaskRepository.getAllTasks()`. La pregunta fue: **¿debe `DashboardNotifier` depender de `TasksNotifier` para obtener las tareas, o debe acceder al repositorio directamente?**

Las dos aproximaciones tienen consecuencias distintas sobre acoplamiento, ciclo de vida y testabilidad.

## Decisión

### `DashboardNotifier` accede a `TaskRepository` directamente a través de sus use cases

```dart
class DashboardNotifier extends StateNotifier<DashboardState> {
  DashboardNotifier({
    required GetDashboardStatsUseCase getDashboardStats,
    required GetRecentActivityUseCase getRecentActivity,
  }) ...

  Future<void> loadDashboard() async {
    state = const DashboardLoading();
    final statsResult    = await _getDashboardStats();     // → TaskRepository.getAllTasks()
    final activityResult = await _getRecentActivity();    // → TaskRepository.getAllTasks()
    ...
  }
}
```

`DashboardNotifier` es un `StateNotifier` independiente, con su propio ciclo de carga (`loadDashboard()` / `refresh()`), sin saber que `TasksNotifier` existe.

Los providers del dashboard dependen de `taskRepositoryProvider`, no de `tasksNotifierProvider`:

```dart
final getDashboardStatsUseCaseProvider = Provider<GetDashboardStatsUseCase>(
  (ref) => GetDashboardStatsUseCase(ref.watch(taskRepositoryProvider)),
);
```

### Por qué no depender de `TasksNotifier`

La alternativa habría sido:

```dart
final dashboardNotifierProvider = StateNotifierProvider((ref) {
  final tasksState = ref.watch(tasksNotifierProvider);  // acoplamiento fuerte
  ...
});
```

Esto introduce varios problemas:

- **Acoplamiento de ciclos de vida**: si `TasksNotifier` no ha cargado aún, `DashboardNotifier` no puede mostrar datos aunque el repositorio esté disponible.
- **Orden de inicialización frágil**: `DashboardPage` tendría que esperar a que `TaskListPage` cargue sus datos (o disparar `loadTasks()` antes de `loadDashboard()`), creando una dependencia implícita entre pantallas.
- **Tests más complejos**: los tests de `DashboardNotifier` necesitarían mockear `TasksNotifier` o proveer un `ProviderScope` con toda la cadena, en lugar de mockear solo `GetDashboardStatsUseCase`.
- **`TasksNotifier` y `DashboardNotifier` tienen contratos distintos**: el primero gestiona CRUD y operaciones de escritura; el segundo es solo lectura para el dashboard. Fusionar sus fuentes de datos acoplaría ciclos de vida que deben ser independientes.

## Consecuencias

### Positivas

- **`DashboardNotifier` funciona en aislamiento**: `DashboardPage` puede cargarse sin importar si el usuario ha visitado `TaskListPage`. No hay dependencias de orden.
- **Tests unitarios simples**:
  ```dart
  // Solo se mockea el use case, sin cadena de providers
  when(() => getStats()).thenAnswer((_) async => const Right(_sampleStats));
  await notifier.loadDashboard();
  expect(notifier.state, isA<DashboardLoaded>());
  ```
- **Principio de responsabilidad única**: `TasksNotifier` gestiona el CRUD de tareas; `DashboardNotifier` agrega datos para visualización. Son responsabilidades distintas que merecen notifiers distintos.
- **Preparación para Phase 4**: cuando Firestore reemplace el datasource in-memory, cada notifier puede suscribirse a su propio stream de Firestore de forma independiente, con queries optimizadas diferentes (CRUD vs. queries de agregación).

### Negativas / Trade-offs

- **Doble llamada a `getAllTasks()`**: cuando tanto `DashboardPage` como `TaskListPage` están montadas al mismo tiempo, el repositorio recibe dos llamadas independientes. Con `InMemoryTaskDatasource` esto es inofensivo (O(1), sin IO). Con Firestore, estas serían dos reads facturadas. Mitigación en Phase 4: Firestore listeners (streams) en lugar de reads puntuales, o un `Provider<List<Task>>` compartido como caché.
- **Datos potencialmente desincronizados**: si el usuario crea una tarea en `TaskListPage` y luego vuelve al dashboard sin recargar, los contadores pueden estar desactualizados. La mitigación actual es llamar `refresh()` en `DashboardPage.initState` / al reentrar al tab. Una solución más robusta (streams reactivos) se difiere a Phase 4.
- **`getAllTasks()` se llama dos veces en `loadDashboard()`**: una para stats y otra para actividad reciente. Esto podría unificarse en un único use case `GetDashboardDataUseCase` que devuelva stats + recientes en un solo viaje. Se evaluará si la complejidad lo justifica en Phase 4.

## Relación con ADRs previas

- [Phase 1 — ADR-002](../adr-phase-01/ADR-002-riverpod-state-management.md): el proyecto usa múltiples `StateNotifier` independientes por feature. `DashboardNotifier` sigue este patrón en lugar de centralizar estado en un único notifier global.
- [Phase 2 — ADR-003](../adr-phase-02/ADR-003-in-memory-task-datasource-placeholder.md): `InMemoryTaskDatasource` es temporal. La independencia de `DashboardNotifier` facilita la migración en Phase 4 sin refactorizar la lógica de presentación del dashboard.

## Alternativas consideradas

| Alternativa | Descartada porque |
|---|---|
| `DashboardNotifier` observa `tasksNotifierProvider` | Acoplamiento de ciclos de vida; tests más complejos; orden de inicialización implícito entre pantallas |
| `Provider<TaskStats>` computado que observa `tasksNotifierProvider` | Elimina el notifier propio pero no tiene estado `loading`/`error` propio para el dashboard |
| Un único `AppNotifier` global con todos los datos | Anti-pattern God Object; imposible de testear en aislamiento; viola SRP |
| `GetDashboardDataUseCase` unificado (stats + recientes en un call) | Optimización válida, pero prematura para Phase 3 con in-memory; se revisa en Phase 4 |
