# ADR-003: `TaskModel.fromFirestore/toFirestore` — Timestamp ↔ DateTime como responsabilidad del modelo

**Estado:** Aceptado  
**Fecha:** 2026-06-01  
**Fase:** Phase 4 — Backend Integration MVP  
**Tags:** data-layer, model, serialization, firestore, timestamp

---

## Contexto

Firestore almacena fechas como `Timestamp` (un tipo propio del SDK de `cloud_firestore`). La entidad de dominio `Task` usa `DateTime` de Dart. La conversión entre ambos tipos debe ocurrir en algún punto de la cadena.

`TaskModel` ya existía desde Phase 2 con `fromJson`/`toJson` (serialización ISO-8601 para el datasource en memoria). En Phase 4 se añade soporte Firestore. La pregunta fue: **¿se añaden los métodos de Firestore al modelo existente, o se crea una clase aparte?**

## Decisión

### Métodos `fromFirestore` / `toFirestore` añadidos a `TaskModel`

```dart
factory TaskModel.fromFirestore(Map<String, dynamic> data, String id) {
  return TaskModel(
    id: id,  // el id viene del DocumentSnapshot, no del mapa
    title:       data['title']       as String,
    description: data['description'] as String? ?? '',
    dueDate:    (data['dueDate']    as Timestamp).toDate(),
    category:    data['category']   as String? ?? 'Personal',
    priority:    TaskPriority.values.byName(data['priority'] as String? ?? 'medium'),
    isCompleted: data['isCompleted'] as bool? ?? false,
    createdAt:  (data['createdAt']  as Timestamp).toDate(),
    updatedAt:  (data['updatedAt']  as Timestamp).toDate(),
  );
}

Map<String, dynamic> toFirestore(String userId) {
  return {
    'userId':      userId,
    'title':       title,
    'description': description,
    'dueDate':     Timestamp.fromDate(dueDate),
    'category':    category,
    'priority':    priority.name,
    'isCompleted': isCompleted,
    'createdAt':   Timestamp.fromDate(createdAt),
    'updatedAt':   Timestamp.fromDate(updatedAt),
  };
}
```

Diferencias clave respecto a `fromJson`/`toJson`:

| Aspecto | `fromJson` / `toJson` | `fromFirestore` / `toFirestore` |
|---|---|---|
| Formato de fecha | `String` ISO-8601 | `Timestamp` de Firestore |
| Campo `id` | dentro del mapa JSON | en el `DocumentSnapshot` (parámetro separado) |
| Campo `userId` | no existe | añadido en `toFirestore` para filtrar por usuario |
| Campos opcionales | ninguno | `description`, `category`, `priority`, `isCompleted` con defaults |

## Consecuencias

### Positivas

- **`TaskModel` como único punto de serialización**: toda la lógica de conversión hacia/desde representaciones externas (JSON, Firestore) vive en el modelo. El datasource no contiene código de serialización.
- **Defaults para campos opcionales en `fromFirestore`**: documentos legados o creados sin todos los campos no causan `null` exceptions — se aplica un valor razonable.
- **El id viene del `DocumentSnapshot`**: Firestore separa el id del mapa de datos; `fromFirestore` acepta ambos como parámetros, lo que refleja fielmente la API del SDK.
- **`userId` solo en `toFirestore`**: el campo de pertenencia se añade al escribir, sin contaminar la entidad de dominio `Task` (que no conoce al usuario propietario — responsabilidad de la capa data).

### Negativas / Trade-offs

- **`TaskModel` importa `cloud_firestore`**: la dependencia del SDK de Firestore entra en la capa `data/models`. Aceptable porque el modelo es explícitamente infraestructura de datos — no cruza a dominio.
- **Dos representaciones distintas en el mismo `TaskModel`**: si en el futuro se añade otra fuente (SQLite, API REST), el modelo acumularía más métodos. Umbral de refactor: >3 formatos distintos justifican un `TaskMapper` por fuente.

## Alternativas consideradas

| Alternativa | Descartada porque |
|---|---|
| `FirestoreTaskModel` subclase separada | Duplica todos los campos de `TaskModel`; no hay diferencia de dominio entre ambas representaciones |
| Conversión Timestamp↔DateTime en el datasource | El datasource quedaría lleno de lógica de serialización que pertenece al modelo |
| Guardar `DateTime` como String en Firestore | Firestore ordena por `Timestamp` nativo; guardar ISO-8601 impide queries de rango eficientes |
| Convertir en el use case | Rompe la separación de capas — el use case opera con entidades de dominio, no con tipos de SDK |
