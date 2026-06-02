# ADR-007: Tareas en colección plana con campo `userId` en lugar de sub-colecciones por usuario

**Estado:** Aceptado  
**Fecha:** 2026-06-01  
**Fase:** Phase 4 — Backend Integration MVP  
**Tags:** firestore, data-model, scalability, security, multitenancy

---

## Contexto

Firestore ofrece dos formas canónicas de organizar datos multi-usuario:

**Opción A — Sub-colecciones**: `/users/{userId}/tasks/{taskId}`  
**Opción B — Colección plana con campo**: `/tasks/{taskId}` con campo `userId` en el documento

La decisión afecta queries, reglas de seguridad, capacidad de hacer queries cruzadas de usuario (admin), y la estructura del `FirebaseTaskDatasource`.

## Decisión

### Colección plana `/tasks` con campo `userId` en cada documento

```dart
Map<String, dynamic> toFirestore(String userId) {
  return {
    'userId': userId,   // campo de pertenencia
    'title': title,
    'description': description,
    'dueDate': Timestamp.fromDate(dueDate),
    // ...
  };
}
```

Las queries filtran por este campo:

```dart
await _col.where('userId', isEqualTo: _userId).get();
```

El Firestore Security Rule correspondiente:

```javascript
// Firestore rules (fuera del scope del código Dart)
match /tasks/{taskId} {
  allow read, write: if request.auth.uid == resource.data.userId;
  allow create: if request.auth.uid == request.resource.data.userId;
}
```

## Consecuencias

### Positivas

- **Modelo simple, queries directas**: `_col.where('userId', isEqualTo: uid)` es una sola línea. No hay que construir rutas dinámicas como `_firestore.collection('users').doc(uid).collection('tasks')`.
- **Facilita queries de admin y analytics**: un panel de administración puede hacer `_col.where('userId', isEqualTo: X)` para cualquier usuario, o incluso queries cross-user con `where('priority', isEqualTo: 'high')` sin path dinámico.
- **Consistente con el modelo de datos actual**: `Task` en dominio no tiene ninguna referencia a su propietario. `userId` se añade solo al serializar — el dominio permanece puro.
- **Índice compuesto en Firestore**: si se necesita ordenar por `dueDate` y filtrar por `userId`, Firestore crea el índice compuesto automáticamente la primera vez que se ejecuta la query.

### Negativas / Trade-offs

- **Las Firestore Security Rules son más complejas**: con sub-colecciones, `match /users/{userId}/tasks/{taskId}` garantiza automáticamente que `userId` en el path == UID autenticado. Con colección plana, la regla debe verificar `resource.data.userId == request.auth.uid` explícitamente en cada operación.
- **Sin aislamiento estructural de datos**: si las Security Rules tienen un bug, un usuario podría leer datos de otro. Con sub-colecciones, el path actúa como primera línea de defensa.
- **Límite de 1 MB por documento no cambia**, pero el límite de escrituras concurrentes a la misma colección puede ser relevante a escala (>1 escritura/seg por documento — no aplica para MVP).

## Alternativas consideradas

| Alternativa | Descartada porque |
|---|---|
| Sub-colección `/users/{uid}/tasks/{id}` | Requiere que `FirebaseTaskDatasource` conozca el path del usuario en cada operación; más verboso sin beneficio real en MVP mono-usuario |
| Colección separada por usuario (`tasks_{uid}`) | Anti-patrón de Firestore; no escala con muchos usuarios; no permite queries con `collectionGroup` |
| Guardar `userId` solo en los metadatos del documento (no en los datos) | Firestore no diferencia metadatos de datos; el campo debe estar en el mapa para filtrar |

## Deuda técnica generada

Implementar y revisar las Firestore Security Rules antes de ir a producción. La regla mínima para MVP:

```javascript
match /databases/{database}/documents {
  match /tasks/{taskId} {
    allow read, update, delete: if request.auth != null
      && resource.data.userId == request.auth.uid;
    allow create: if request.auth != null
      && request.resource.data.userId == request.auth.uid;
  }
}
```

Sin estas reglas, cualquier usuario autenticado puede leer o modificar las tareas de otro usuario.
