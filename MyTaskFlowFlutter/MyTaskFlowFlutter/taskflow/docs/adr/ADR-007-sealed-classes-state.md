# ADR-007: Sealed classes para representación de estado

- **Estado**: Aceptado
- **Fecha**: 2026-06-01
- **Fase**: 1 — Auth MVP

## Contexto

Cada feature con estado asíncrono (autenticación, lista de tareas) necesita representar al menos cuatro condiciones: estado inicial, cargando, éxito, error. La UI debe reaccionar de forma diferente a cada una.

Las alternativas evaluadas:

| Opción | Problema |
|--------|----------|
| `bool isLoading` + `String? error` + `T? data` en el mismo objeto | Combinaciones inválidas posibles: `isLoading=true` y `data!=null` al mismo tiempo. |
| `enum State { initial, loading, loaded, error }` con campos opcionales | No compile-safe; requiere castings o null checks en la UI. |
| **Sealed classes** | **Seleccionado.** Exhaustive `switch`, tipos distintos por estado, sin campos opcionales. |

## Decisión

Cada feature usa una **sealed class** de estado con subtipos concretos:

```dart
// Ejemplo: TasksState
sealed class TasksState {}

class TasksInitial  extends TasksState {}
class TasksLoading  extends TasksState {}
class TasksLoaded   extends TasksState { final List<TaskEntity> tasks; ... }
class TasksError    extends TasksState { final String message; ... }
class TasksEmpty    extends TasksState {}
```

La UI hace `switch` exhaustivo sobre el estado:

```dart
switch (state) {
  TasksInitial()  => const SizedBox.shrink(),
  TasksLoading()  => const CircularProgressIndicator(),
  TasksLoaded(tasks: final t) => TaskListView(tasks: t),
  TasksError(message: final m) => ErrorBanner(message: m),
  TasksEmpty()    => const EmptyStateWidget(),
}
```

Si se añade un nuevo subtipo de estado, el compilador fuerza a actualizar todos los `switch` que no tengan `default`.

## Consecuencias

**Positivas:**
- Imposible representar estados contradictorios (no existe `TasksLoaded` con `tasks == null`).
- El `switch` exhaustivo garantiza que la UI maneja todos los estados posibles.
- El patrón es idéntico para `AuthState` y `TasksState`, lo que reduce la curva de aprendizaje al añadir nuevas features.
- Los tests verifican el tipo exacto del estado, no campos individuales.

**Negativas / trade-offs:**
- Dart sealed classes requieren Dart 3.0+; no compatible con proyectos más antiguos (no aplica aquí).
- Añadir un nuevo subtipo de estado puede requerir actualizar muchos `switch` si el estado se consume en muchos lugares.
- Más archivos que un único objeto de estado plano (aunque en este proyecto `state.dart` agrupa todos los subtipos).
