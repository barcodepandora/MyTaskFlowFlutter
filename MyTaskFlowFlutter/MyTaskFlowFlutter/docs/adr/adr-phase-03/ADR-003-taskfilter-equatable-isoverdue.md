# ADR-003: TaskFilter extendido con Equatable e `isOverdue`

**Estado:** Aceptado  
**Fecha:** 2026-06-01  
**Fase:** Phase 3 — Dashboard & Search/Filter MVP  
**Tags:** domain, filter, equatable, value-object, ui-binding

---

## Contexto

En Phase 2, `TaskFilter` era un data class sin Equatable:

```dart
class TaskFilter {
  const TaskFilter({ this.keyword, this.category, this.priority, this.isCompleted });
  ...
}
```

Phase 3 introdujo dos necesidades nuevas:

1. **`FilterChips` necesita comparar filtros por valor** para determinar cuál chip está activo. Sin Equatable, `activeFilter == const TaskFilter(isCompleted: false)` siempre es `false` (comparación por referencia).
2. **El chip "Vencidas"** necesita expresar un filtro de tareas con `dueDate` en el pasado. `TaskFilter` no tenía este campo.

## Decisión

### Extender `TaskFilter` con `Equatable` y añadir `isOverdue: bool?`

```dart
class TaskFilter extends Equatable {
  const TaskFilter({
    this.keyword,
    this.category,
    this.priority,
    this.isCompleted,
    this.isOverdue,         // nuevo campo
  });

  final String? keyword;
  final String? category;
  final TaskPriority? priority;
  final bool? isCompleted;
  final bool? isOverdue;    // nuevo campo

  @override
  List<Object?> get props => [keyword, category, priority, isCompleted, isOverdue];
}
```

`InMemoryTaskDatasource.searchTasks()` se actualiza para respetar `isOverdue`:

```dart
if (filter.isOverdue == true) {
  result = result.where((t) => t.isOverdue).toList();
}
```

Los chips de `FilterChips` usan instancias `const` que se comparan correctamente:

```dart
static const _options = [
  (label: 'Todos',          filter: TaskFilter()),
  (label: 'Pendiente',      filter: TaskFilter(isCompleted: false)),
  (label: 'Completado',     filter: TaskFilter(isCompleted: true)),
  (label: 'Alta prioridad', filter: TaskFilter(priority: TaskPriority.high)),
  (label: 'Vencidas',       filter: TaskFilter(isOverdue: true)),
];

final isSelected = activeFilter == opt.filter;  // ✅ funciona por valor
```

### Por qué `isOverdue` va en `TaskFilter` y no en un enum aparte

La alternativa era un `FilterOption` enum en la capa de presentación:

```dart
enum FilterOption { all, pending, completed, highPriority, overdue }
```

Se rechazó porque `SearchNotifier` habría necesitado traducir `FilterOption → TaskFilter` y `InMemoryTaskDatasource` habría quedado sin soporte nativo de `isOverdue`. Al extender `TaskFilter`, el pipeline `FilterChips → SearchNotifier._applyFilters() → datasource.searchTasks()` usa un solo tipo de extremo a extremo.

## Consecuencias

### Positivas

- **Chips reactivos sin overhead**: `FilterChips` no necesita estado interno ni lógica de comparación propia. El widget es stateless; solo compara `activeFilter == opt.filter` usando Equatable.
- **`SearchState` incluye `filter: TaskFilter` en sus `props`**: Riverpod detecta cambios de filtro y reconstruye solo los widgets necesarios.
- **El test de `FilterChips` puede verificar valores exactos**:
  ```dart
  await tester.tap(find.text('Pendiente'));
  expect(received, const TaskFilter(isCompleted: false));  // Equatable hace esto posible
  ```
- **`const TaskFilter()` es el estado "sin filtro"**: la ausencia de valor en todos los campos representa "Todos" sin necesitar un `FilterOption.all` especial.

### Negativas / Trade-offs

- `isOverdue` es semánticamente diferente a los otros campos: `isCompleted`, `priority` y `keyword` son atributos directos de la tarea; `isOverdue` es un atributo **computado** (`!isCompleted && dueDate < now`). Tenerlo en `TaskFilter` como si fuera un campo de datos introduce una ligera asimetría conceptual.
- `props` incluye `isOverdue`, lo que significa que `TaskFilter(isOverdue: true)` y `TaskFilter(isOverdue: false)` son distintos aunque ambos podrían representar "filtrar por estado de vencimiento". Esto es correcto y deseado, pero requiere que los creadores de filtros sean precisos con el valor booleano.
- Si en Phase 4 Firestore requiere construir queries con `isOverdue`, será necesario calcular `DateTime.now()` en la capa de datos para comparar con `dueDate`, ya que Firestore no evalúa getters de Dart. El campo `isOverdue: bool?` en `TaskFilter` actúa como señal de intención; la implementación concreta del repositorio decide cómo materializarla.

## Relación con ADRs previas

- [Phase 2 — ADR-001](../adr-phase-02/ADR-001-task-entity-equatable-uuid-factory.md): `Task.isOverdue` es un getter computado en la entidad. `TaskFilter.isOverdue` es un criterio de búsqueda que se materializa llamando ese mismo getter en `_applyFilters()`.
- [Phase 1 — ADR-007](../adr-phase-01/ADR-007-equatable-entity-equality.md): el proyecto usa Equatable consistentemente en todas las entidades y value objects. `TaskFilter` se alinea con esa convención.

## Alternativas consideradas

| Alternativa | Descartada porque |
|---|---|
| `enum FilterOption` en capa de presentación | Requiere traducción `FilterOption → TaskFilter` en `SearchNotifier`; duplica conceptos; `InMemoryTaskDatasource` no se beneficia |
| Mantener comparación manual en `FilterChips` | Frágil: si se añade un campo a `TaskFilter`, la comparación manual queda desactualizada silenciosamente |
| `TaskFilter` sin `isOverdue`, filtrar vencidas en `SearchNotifier` solamente | El datasource quedaría inconsistente: `searchTasks(filter)` no manejaría `isOverdue` aunque recibiera un filtro de vencidas implícito |
