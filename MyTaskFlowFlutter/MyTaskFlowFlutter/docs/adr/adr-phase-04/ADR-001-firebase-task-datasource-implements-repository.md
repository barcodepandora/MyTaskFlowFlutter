# ADR-001: `FirebaseTaskDatasource` implementa `TaskRepository` directamente

**Estado:** Aceptado  
**Fecha:** 2026-06-01  
**Fase:** Phase 4 — Backend Integration MVP  
**Tags:** clean-architecture, datasource, repository, firebase, layers

---

## Contexto

En la Clean Architecture tradicional la capa `data` tiene dos responsabilidades separadas:

1. **Repository implementation** — orquesta uno o más datasources, maneja lógica de caché, decide qué fuente usar.
2. **Datasource** — contiene el detalle técnico de una fuente concreta (red, BD local, etc.).

En fases anteriores `InMemoryTaskDatasource` era un datasource real que el provider inyectaba directamente en `TaskRepository`. La pregunta de Phase 4 fue: al añadir Firebase, ¿creamos una clase `TaskRepositoryImpl` que delegue a `FirebaseTaskDatasource`, o el datasource implementa el repositorio directamente?

## Decisión

### `FirebaseTaskDatasource` implementa `TaskRepository`

```dart
class FirebaseTaskDatasource implements TaskRepository {
  FirebaseTaskDatasource({
    required FirebaseFirestore firestore,
    required fb.FirebaseAuth auth,
  });

  @override
  Future<Either<Failure, List<Task>>> getAllTasks() async { ... }
  // ... todos los métodos de TaskRepository
}
```

El provider registra directamente esta clase:

```dart
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return FirebaseTaskDatasource(
    firestore: FirebaseFirestore.instance,
    auth: fb.FirebaseAuth.instance,
  );
});
```

## Consecuencias

### Positivas

- **Sin clases vacías de delegación**: una `TaskRepositoryImpl` que solo llama a `datasource.method()` no aporta valor real en el MVP; solo añade indirección.
- **Facilita el swap**: los tests reemplazan el provider con `InMemoryTaskDatasource` (que también implementa `TaskRepository`) con una línea, sin tocar la jerarquía.
- **Precedente coherente**: `InMemoryTaskDatasource` ya lo hacía así en fases 2-3; `RemoteAuthDatasource` sigue el mismo patrón.

### Negativas / Trade-offs

- **Mezcla responsabilidades cuando hay multi-fuente**: si en Phase 5+ necesitamos caché local (Hive/SQLite) + Firestore como fuentes simultáneas, el datasource ya no puede implementar el repositorio directamente; habrá que introducir `TaskRepositoryImpl` con lógica `offline-first`. Este momento de refactor está documentado como deuda técnica.
- **No hay lugar natural para lógica de reconciliación de conflictos** entre fuentes hasta que se introduzca la capa repositorio real.

## Alternativas consideradas

| Alternativa | Descartada porque |
|---|---|
| `TaskRepositoryImpl` con `FirebaseTaskDatasource` interno | Para MVP con una sola fuente de datos, agrega una clase de pass-through sin comportamiento propio |
| Datasource separado + repositorio con caché en memoria | Complejidad prematura — sin requerimiento de offline para Phase 4 |
| `abstract class FirebaseTaskDatasource extends TaskRepository` | Semánticamente incorrecto; `extends` implica herencia, no implementación de contrato |

## Deuda técnica generada

Cuando se añada soporte offline (Hive/SQLite), introducir `TaskRepositoryImpl` que coordine `LocalTaskDatasource` + `RemoteTaskDatasource`, ambos con interfaces propias. En ese momento, `FirebaseTaskDatasource` pasará a ser un datasource remoto puro y dejará de implementar `TaskRepository`.
