# ADR-002: `ProfileRepository` retorna `AuthUser` en lugar de una entidad `Profile` propia

**Estado:** Aceptado  
**Fecha:** 2026-06-02  
**Fase:** Phase 5 — Profile & Settings MVP  
**Tags:** domain, clean-architecture, entities, cross-feature, profile, auth

---

## Contexto

Phase 5 introduce la feature `profile/` con su propio dominio. La operación central es `updateDisplayName` — el usuario edita su nombre visible. Tras actualizar, la app debe reflejar el nombre nuevo en toda la UI (el avatar en la tab de perfil y potencialmente el saludo del dashboard).

La pregunta de diseño fue: **¿debe `ProfileRepository` operar sobre una entidad `Profile` propia, o puede retornar `AuthUser` directamente?**

```dart
// Opción A — entidad propia
abstract class ProfileRepository {
  Future<Either<Failure, Profile>> updateDisplayName(String name);
}

// Opción B — retorna AuthUser
abstract class ProfileRepository {
  Future<Either<Failure, AuthUser>> updateDisplayName(String name);
}
```

## Decisión

### `ProfileRepository` retorna `AuthUser` (Opción B)

```dart
abstract class ProfileRepository {
  Future<Either<Failure, AuthUser>> updateDisplayName(String name);
}
```

La lógica: en Firebase, `displayName` es un campo del usuario autenticado (`FirebaseUser`). No existe un documento "perfil" separado — el nombre ya es parte del modelo `AuthUser`. Crear una entidad `Profile` solo para envolver `displayName` y `email` sería una abstracción sin sustancia propia.

`ProfileNotifier` recibe el `AuthUser` actualizado y lo propaga al estado auth:

```dart
// ProfilePage — sincroniza AuthNotifier tras actualizar perfil
ref.listen<ProfileState>(profileNotifierProvider, (_, next) {
  if (next is ProfileUpdated) {
    ref.read(authNotifierProvider.notifier).updateUser(next.user);
  }
});
```

## Consecuencias

### Positivas

- **Sin duplicación de entidades**: `AuthUser` ya tiene `uid`, `email` y `displayName`. Crear `Profile(displayName, email)` sería un subconjunto redundante.
- **Sincronización directa**: `ProfileNotifier` retorna un `AuthUser` completo que `AuthNotifier.updateUser()` puede consumir directamente. No hay transformación ni mapping adicional.
- **Coherente con Firebase**: la fuente de verdad del perfil en Firebase es `FirebaseUser`; mapear a `AuthUser` en el datasource es la traducción natural.

### Negativas / Trade-offs

- **Acoplamiento entre `profile/` y `auth/`**: `ProfileRepository` importa `AuthUser` desde la feature `auth/`. En una arquitectura de bounded contexts estrictos, `profile/` tendría su propia entidad y un mapper. Para este MVP con un solo servidor de identidad (Firebase), el acoplamiento es aceptable.
- **Escalabilidad limitada**: si en el futuro el perfil añade campos que no existen en `AuthUser` (bio, avatar URL en Storage, preferencias avanzadas), habrá que crear la entidad `Profile` propia. En ese momento, este ADR queda Superado.

## Alternativas consideradas

| Alternativa | Descartada porque |
|---|---|
| Entidad `Profile` propia | Envuelve exactamente los mismos campos que `AuthUser`; puro overhead sin comportamiento propio |
| `ProfileRepository` retorna `void` | La UI necesita el nombre actualizado para redibujar el avatar sin hacer un segundo fetch |
| `ProfileRepository` retorna `String` (solo el nombre) | Insuficiente si se añaden más campos al perfil; fuerza cambios de firma en el futuro cercano |
