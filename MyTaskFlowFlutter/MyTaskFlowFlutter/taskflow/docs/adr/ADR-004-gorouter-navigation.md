# ADR-004: GoRouter para navegación declarativa

- **Estado**: Aceptado
- **Fecha**: 2026-06-01
- **Fase**: 0 — Fundación

## Contexto

La app necesita:
- Proteger rutas según el estado de autenticación (redirigir a login si no autenticado).
- Soportar deep links en el futuro (web y móvil).
- Pasar entidades entre pantallas de forma tipada (lista de tareas → detalle de tarea).
- Mantener la lógica de redirección fuera de los widgets.

Las alternativas evaluadas:

| Solución | Por qué se descartó |
|----------|---------------------|
| `Navigator 1.0` (`push`/`pop`) | No soporta deep links nativamente. Lógica de guards dispersa en widgets. |
| `Navigator 2.0` / Router API | Poderoso pero muy verboso. Requiere implementar `RouterDelegate` y `RouteInformationParser` manualmente. |
| **auto_route** | Buena alternativa, pero genera mucho código via build_runner. Añade complejidad de compilación. |
| **GoRouter** | **Seleccionado.** Declarativo, soporta guards reactivos, oficial de Flutter team. |

## Decisión

Se usa **GoRouter v14** con `redirect` reactivo basado en el estado de autenticación:

```dart
redirect: (context, state) {
  final authState = ref.read(authNotifierProvider);
  final isLoggedIn = authState is AuthAuthenticated;
  final isOnLogin  = state.matchedLocation == '/login';

  if (!isLoggedIn && !isOnLogin) return '/login';
  if (isLoggedIn  &&  isOnLogin) return '/tasks';
  return null;
},
refreshListenable: authListenable,  // re-evalúa redirect al cambiar auth
```

Rutas definidas en `core/router/app_router.dart`:

| Ruta | Página |
|------|--------|
| `/login` | LoginPage |
| `/tasks` | TaskListPage |
| `/tasks/new` | TaskFormPage (creación) |
| `/tasks/:id` | TaskDetailPage |
| `/tasks/:id/edit` | TaskFormPage (edición) |

La entidad `TaskEntity` se pasa via `extra` en `GoRouterState` para evitar serializar/deserializar en la URL.

## Consecuencias

**Positivas:**
- La lógica de guards está centralizada en un solo lugar, no en cada `initState`.
- Compatible con deep links web y móvil sin cambios adicionales.
- Fácil de testear: el router reacciona a cambios del provider de auth.

**Negativas / trade-offs:**
- `extra` no sobrevive a hot restart ni a deep links externos (el objeto no puede ser reconstruido desde una URL). Para Phase 3+, las rutas de detalle deberán resolver la entidad por ID desde Firestore.
- GoRouter cambia de versión mayor frecuentemente (v14 → v17 disponible). La API de `extra` es estable, pero las actualizaciones requieren revisión.
