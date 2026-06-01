# ADR-002: SearchNotifier — filtrado local sincrónico en lugar de async use case

**Estado:** Aceptado  
**Fecha:** 2026-06-01  
**Fase:** Phase 3 — Dashboard & Search/Filter MVP  
**Tags:** search, state-management, riverpod, ux, performance, sync

---

## Contexto

`TaskListPage` necesita filtrar la lista de tareas en tiempo real mientras el usuario escribe y selecciona chips. Existe un `SearchTasksUseCase` que ya realiza este filtrado, pero su contrato es asíncrono:

```dart
Future<Either<Failure, List<Task>>> call(TaskFilter filter) =>
    _repository.searchTasks(filter);
```

La pregunta fue: **¿debe `SearchNotifier` llamar al use case async en cada keystroke, o filtrar localmente de forma síncrona sobre la lista ya cargada?**

El contexto tiene una restricción importante: el datasource actual es `InMemoryTaskDatasource`. No hay latencia de red ni de disco. La lista completa de tareas ya está en memoria en `TasksNotifier`.

## Decisión

### Filtrado local sincrónico dentro de `SearchNotifier`

`SearchNotifier` mantiene internamente `_allTasks: List<Task>` y aplica filtros de forma síncrona:

```dart
class SearchNotifier extends StateNotifier<SearchState> {
  List<Task> _allTasks = [];

  void updateQuery(String query) {
    state = state.copyWith(query: query);
    _applyFilters();          // sync, no await
  }

  void _applyFilters() {
    var tasks = List<Task>.from(_allTasks);

    if (state.query.isNotEmpty) {
      final kw = state.query.toLowerCase();
      tasks = tasks.where((t) =>
        t.title.toLowerCase().contains(kw) ||
        t.description.toLowerCase().contains(kw)
      ).toList();
    }
    if (state.filter.priority != null) { ... }
    if (state.filter.isCompleted != null) { ... }
    if (state.filter.isOverdue == true) { ... }

    state = state.copyWith(filteredTasks: tasks);
  }
}
```

La sincronización con `TasksNotifier` se hace mediante `ref.listen` dentro del provider, con `fireImmediately: true`:

```dart
final searchNotifierProvider = StateNotifierProvider<SearchNotifier, SearchState>(
  (ref) {
    final notifier = SearchNotifier();
    ref.listen<TasksState>(tasksNotifierProvider, (_, next) {
      if (next is TasksLoaded) notifier.updateTasks(next.tasks);
    }, fireImmediately: true);
    return notifier;
  },
);
```

El debounce de 300ms vive en el widget `TaskSearchBar`, no en el notifier:

```dart
_debounce = Timer(const Duration(milliseconds: 300), () {
  widget.onChanged(value);
});
```

Esto separa la política de UX (cuándo dejar de esperar) de la lógica de filtrado (cómo filtrar).

## Consecuencias

### Positivas

- **Respuesta instantánea (<1ms)**: el filtrado no pasa por `await`, no hay jank visible. Con in-memory, el resultado es perceptualmente inmediato.
- **Tests 100% síncronos**: los tests de `SearchNotifier` no necesitan `async`, `Completer` ni `pumpAndSettle`:
  ```dart
  notifier.updateTasks([taskA, taskB]);
  notifier.updateQuery('flutter');
  expect(notifier.state.filteredTasks.length, 1);  // sync assert
  ```
- **Debounce en la capa correcta**: el widget controla el tempo de la UX (300ms). El notifier no sabe nada de timers; permanece puro y testeable.
- **`ref.listen` con `fireImmediately: true`** garantiza que el estado inicial de `SearchNotifier` refleja las tareas ya cargadas si `TasksNotifier` ya está en `TasksLoaded` al momento de crear el provider.

### Negativas / Trade-offs

- **Duplicación de lógica de filtrado**: `_applyFilters()` replica la lógica de `InMemoryTaskDatasource.searchTasks()`. Si se añade un nuevo criterio de filtro, debe actualizarse en dos lugares. Mitigado por la naturaleza temporal de `InMemoryTaskDatasource` (Phase 4 lo reemplazará con Firestore).
- **Deuda hacia Phase 4**: cuando el backend sea Firestore, el filtrado en cliente dejará de ser viable para colecciones grandes. `SearchNotifier` deberá refactorizarse para llamar al use case async. La interfaz pública (`updateQuery`, `updateFilter`, `clearFilters`) no cambia, solo la implementación de `_applyFilters`.
- **`_allTasks` es una copia**: cada llamada a `_applyFilters` crea una nueva `List<Task>` con `List.from()`. Para 6–100 tareas es negligible; para miles de tareas requeriría optimización (lazy evaluation, índices).

## Regla de migración hacia Phase 4

Cuando se integre Firestore:

1. `_applyFilters()` se convierte en `Future<void> _applyFilters()` y llama al use case.
2. El debounce en `TaskSearchBar` permanece igual — no hay cambio de contrato en la vista.
3. Los tests del notifier pasan a ser `async` con mocks del use case.
4. `ref.listen` en el provider puede eliminarse si Firestore provee streams reactivos directamente.

## Alternativas consideradas

| Alternativa | Descartada porque |
|---|---|
| Llamar `SearchTasksUseCase` async en cada keystroke | Introduce `await` en la ruta crítica de UX; requiere manejo de estado `loading` para cada filtro; innecesario con in-memory |
| Derivar `filteredTasks` con `Riverpod` `Provider` computed | Un `Provider` que observa `tasksNotifierProvider` y aplica el filtro funciona, pero no guarda el estado del query sin un `StateNotifierProvider` complementario |
| Mover el debounce al notifier | Mezcla política de UX con lógica de negocio; complica los tests (necesitarían `fake_async`) |
| Usar `rxdart` con `debounceTime` | Añade dependencia para una sola feature; `dart:async Timer` es suficiente y sin overhead |
