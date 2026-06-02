# Architecture Decision Records — Phase 5: Profile & Settings MVP

Decisiones arquitectónicas tomadas durante la implementación de la página de perfil, edición del nombre, selector de tema persistente y sincronización del estado de autenticación tras actualizaciones de perfil.

## Formato

```
Estado: Propuesto | Aceptado | Superado | Depreciado
```

---

## Índice

| ADR | Título | Estado | Tags |
|-----|--------|--------|------|
| [ADR-001](ADR-001-theme-notifier-shared-preferences.md) | `ThemeNotifier` con `SharedPreferences` para persistencia del tema | Aceptado | theme, riverpod, shared-preferences, settings |
| [ADR-002](ADR-002-profile-repository-retorna-auth-user.md) | `ProfileRepository` retorna `AuthUser` en lugar de una entidad `Profile` propia | Aceptado | domain, clean-architecture, cross-feature, profile |
| [ADR-003](ADR-003-firebase-profile-datasource-updatename-reload.md) | `FirebaseProfileDatasource` usa `updateDisplayName` + `reload()` | Aceptado | firebase, datasource, profile, reload |
| [ADR-004](ADR-004-auth-notifier-update-user-sync.md) | `AuthNotifier.updateUser()` para sincronizar estado auth tras actualizar perfil | Aceptado | state-management, riverpod, cross-feature, sync |
| [ADR-005](ADR-005-profile-state-sealed-profile-updated.md) | `ProfileState` sealed con `ProfileUpdated(AuthUser)` | Aceptado | sealed-classes, riverpod, presentation, profile |

---

## Decisiones heredadas de fases anteriores

Las siguientes ADRs aplican sin cambios a Phase 5:

- [Clean Architecture en 3 capas](../adr-phase-01/ADR-001-clean-architecture.md) — la feature `profile/` sigue la misma estructura `domain/data/presentation` que `auth/` y `tasks/`.
- [Riverpod como gestor de estado](../adr-phase-01/ADR-002-riverpod-state-management.md) — `ProfileNotifier` y `ThemeNotifier` son `StateNotifier` inyectados via provider.
- [Either<Failure, T> para errores](../adr-phase-01/ADR-004-either-functional-error-handling.md) — `ProfileRepository.updateDisplayName` retorna `Either<Failure, AuthUser>`.
- [`mapFailureToMessage` centralizado](../adr-phase-04/ADR-004-failure-mapper-funcion-pura-presentacion.md) — `ProfileNotifier` lo usa para convertir el `Failure` en mensaje de error para la UI.
- [Tests con Riverpod overrides para aislar Firebase](../adr-phase-04/ADR-006-tests-riverpod-overrides-aislar-firebase.md) — extendido en Phase 5: los tests con `TaskFlowApp` añaden `sharedPreferencesProvider.overrideWithValue(prefs)`.

---

## Deudas técnicas identificadas en Phase 5

| Deuda | Descripción | ADR origen |
|---|---|---|
| Sincronización de perfil solo en `ProfilePage` | Si se añade otra pantalla que permita editar el perfil, hay que replicar el `ref.listen` | ADR-004 |
| `ProfileRepository` importa `AuthUser` | Acoplamiento entre `profile/` y `auth/`; refactorizar si el perfil añade campos propios | ADR-002 |
| Sin caché de perfil offline | Si el usuario no tiene red al abrir `ProfilePage`, no puede editar su nombre — no hay fallback local | ADR-003 |
| `ProfilePlaceholderPage` no eliminada | El archivo sigue existiendo en `presentation/pages/`; puede causar confusión; borrar en siguiente limpieza | — |
