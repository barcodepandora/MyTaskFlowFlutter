# ADR-001: TaskStats como entidad de dominio puro con factory `fromList()`

**Estado:** Aceptado  
**Fecha:** 2026-06-01  
**Fase:** Phase 3 — Dashboard & Search/Filter MVP  
**Tags:** domain, entity, statistics, pure-function, equatable

---

## Contexto

El Dashboard necesita mostrar cuatro contadores derivados de la lista de tareas: total, completadas, pendientes y vencidas. La pregunta de diseño fue **dónde situar el cálculo**:

- En el use case (`GetDashboardStatsUseCase.call()`)
- En el notifier (`DashboardNotifier.loadDashboard()`)
- En el widget directamente
- En una entidad de dominio con factory constructor

La decisión afecta la testabilidad del cálculo, la reusabilidad de la lógica y la pureza de cada capa.

## Decisión

### `TaskStats` como entidad de dominio con factory `fromList()`

```dart
class TaskStats extends Equatable {
  const TaskStats({
    required this.totalTasks,
    required this.completedTasks,
    required this.pendingTasks,
    required this.overdueTasks,
  });

  factory TaskStats.fromList(List<Task> tasks) {
    final completed = tasks.where((t) => t.isCompleted).length;
    final pending   = tasks.where((t) => !t.isCompleted).length;
    final overdue   = tasks.where((t) => t.isOverdue).length;
    return TaskStats(
      totalTasks:      tasks.length,
      completedTasks:  completed,
      pendingTasks:    pending,
      overdueTasks:    overdue,
    );
  }

  double get completionRate =>
      totalTasks == 0 ? 0.0 : completedTasks / totalTasks;

  @override
  List<Object?> get props => [totalTasks, completedTasks, pendingTasks, overdueTasks];
}
```

El use case delega la transformación a la entidad:

```dart
Future<Either<Failure, TaskStats>> call() async {
  final result = await _repository.getAllTasks();
  return result.map(TaskStats.fromList);  // map = Right(TaskStats.fromList(tasks))
}
```

`completionRate` es un getter computado (igual que `isOverdue` en `Task`): se deriva de los campos persistidos y no se incluye en `props`.

## Consecuencias

### Positivas

- **Testabilidad máxima**: `TaskStats.fromList()` es una función pura. Sus tests no necesitan mocks ni async:
  ```dart
  final stats = TaskStats.fromList([taskA, taskB]);
  expect(stats.completedTasks, 1);
  ```
- **El use case queda trivial**: una sola línea con `result.map(...)`, sin lógica de negocio propia. Si el cálculo cambia (ej. añadir `todayTasks`), se modifica solo la entidad.
- **Equatable en `props`** permite que Riverpod detecte cambios reales entre dos cargas del dashboard sin comparar campos individualmente.
- **`completionRate` computado** no puede desincronizarse con los contadores, igual que `isOverdue` en `Task` (precedente de Phase 2).

### Negativas / Trade-offs

- La entidad `TaskStats` depende de `Task` (entidad del mismo dominio). En una arquitectura más estricta con bounded contexts separados, este acoplamiento requeriría un anticorruption layer. Para este MVP, features en el mismo paquete comparten el modelo de dominio sin problema.
- `props` no incluye `completionRate` porque es derivado. Si alguien compara dos `TaskStats` con los mismos contadores pero espera distinguirlas por `completionRate`, el comportamiento de Equatable puede sorprender — documentado como trade-off consciente.

## Alternativas consideradas

| Alternativa | Descartada porque |
|---|---|
| Calcular stats en `DashboardNotifier` | El notifier mezclaría lógica de negocio con orquestación de estado; los tests del notifier tendrían que verificar aritmética, no comportamiento de carga |
| Calcular stats en el use case | El use case debería recibir `List<Task>` y hacer conteos — difumina la responsabilidad entre capa de aplicación y dominio |
| Stats como Map/DTO sin Equatable | Riverpod no detectaría igualdad entre cargas; la UI haría rebuilds innecesarios |
| Incluir `completionRate` en `props` | Campo derivado — si está en props y en los contadores, hay riesgo de inconsistencia en la construcción; el getter garantiza coherencia |
