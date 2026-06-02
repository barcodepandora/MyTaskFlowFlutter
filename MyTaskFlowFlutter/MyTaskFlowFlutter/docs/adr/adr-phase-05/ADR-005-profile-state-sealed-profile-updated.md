# ADR-005: `ProfileState` sealed con `ProfileUpdated(AuthUser)` — el estado de éxito lleva el usuario

**Estado:** Aceptado  
**Fecha:** 2026-06-02  
**Fase:** Phase 5 — Profile & Settings MVP  
**Tags:** state-management, sealed-classes, riverpod, profile, presentation

---

## Contexto

`ProfileNotifier` gestiona el ciclo de vida de la operación `updateDisplayName`. Necesita comunicar cuatro situaciones a la UI: inactivo, cargando, éxito y error. La pregunta fue: **¿qué datos debe llevar el estado de éxito?**

Las opciones son:
- `ProfileUpdated()` sin datos (solo señal de éxito)
- `ProfileUpdated(AuthUser user)` con el usuario actualizado
- `ProfileUpdated(String displayName)` con solo el campo modificado

## Decisión

### `ProfileUpdated(AuthUser user)` — lleva el `AuthUser` completo

```dart
sealed class ProfileState {}
final class ProfileInitial extends ProfileState {
  const ProfileInitial();
}
final class ProfileLoading extends ProfileState {
  const ProfileLoading();
}
final class ProfileUpdated extends ProfileState {
  const ProfileUpdated(this.user);
  final AuthUser user;
}
final class ProfileError extends ProfileState {
  const ProfileError(this.message);
  final String message;
}
```

`ProfileNotifier` asigna `ProfileUpdated` con el `AuthUser` que retorna el use case:

```dart
result.fold(
  (failure) => state = ProfileError(mapFailureToMessage(failure)),
  (user)    => state = ProfileUpdated(user),
);
```

## Consecuencias

### Positivas

- **La UI tiene todos los datos que necesita**: `ProfilePage` puede actualizar el `TextFormField`, el avatar y sincronizar `AuthNotifier` directamente desde `next.user`, sin hacer un segundo fetch.
- **Coherente con el patrón de fases anteriores**: `TasksLoaded(List<Task>)`, `DashboardLoaded(TaskStats, List<Task>)` — todos los estados de éxito llevan el dato resultante. `ProfileUpdated(AuthUser)` sigue la misma convención.
- **El `AuthUser` es inmutable y Equatable**: pasar la referencia es seguro; no hay riesgo de mutación concurrente.

### Negativas / Trade-offs

- **`ProfileState` importa `AuthUser` de otra feature**: el mismo trade-off que en ADR-002. `profile/` sigue dependiendo de `auth/domain`. Aceptable para MVP.
- **El estado de éxito no es un singleton `const`**: `ProfileUpdated(user)` varía por valor de `user`, por lo que Riverpod creará un nuevo estado en cada operación exitosa aunque el nombre no haya cambiado. No es un problema funcional, pero si hay un test que compara estados con `==` necesita `Equatable` o un matcher personalizado.

## Alternativas consideradas

| Alternativa | Descartada porque |
|---|---|
| `ProfileUpdated()` sin datos | Obliga a la UI a hacer un segundo fetch para obtener el nombre nuevo; peor UX y más latencia |
| `ProfileUpdated(String displayName)` | Insuficiente para sincronizar `AuthNotifier` que necesita el `AuthUser` completo (uid + email + displayName) |
| Usar `AsyncNotifier<AuthUser>` de Riverpod | Introduce `AsyncValue` y estados `.loading/.data/.error` — más verboso sin ganancia para una operación puntual sin reactiva continua |
