# ADR-003: `FirebaseProfileDatasource` usa `updateDisplayName` + `reload()` antes de leer el usuario actualizado

**Estado:** Aceptado  
**Fecha:** 2026-06-02  
**Fase:** Phase 5 — Profile & Settings MVP  
**Tags:** firebase, auth, datasource, profile, reload

---

## Contexto

Firebase Auth ofrece `FirebaseUser.updateDisplayName(name)` para cambiar el nombre. El problema: tras llamar a este método, `FirebaseAuth.currentUser` puede devolver el objeto en caché con el nombre anterior si no se fuerza una recarga.

La secuencia correcta para obtener el usuario con los datos nuevos es:

1. `await currentUser.updateDisplayName(name)` — actualiza en el servidor
2. `await currentUser.reload()` — invalida el caché local
3. Leer `FirebaseAuth.currentUser` de nuevo — ahora refleja el cambio

## Decisión

### Patrón `updateDisplayName` + `reload()` + re-lectura

```dart
@override
Future<Either<Failure, AuthUser>> updateDisplayName(String name) async {
  try {
    final fbUser = _firebaseAuth.currentUser;
    if (fbUser == null) return const Left(UnauthorizedFailure());

    await fbUser.updateDisplayName(name);
    await fbUser.reload();                              // invalida caché

    final updated = _firebaseAuth.currentUser!;        // usuario fresco
    return Right(AuthUser(
      uid: updated.uid,
      email: updated.email ?? '',
      displayName: updated.displayName,
    ));
  } on fb.FirebaseAuthException catch (e) {
    return Left(ServerFailure(e.message ?? 'Error al actualizar perfil'));
  } catch (_) {
    return const Left(ServerFailure('Error inesperado al actualizar perfil.'));
  }
}
```

La comprobación `if (fbUser == null)` retorna `UnauthorizedFailure` en lugar de lanzar `NullPointerException` — esto puede ocurrir si la sesión expiró entre el tap y la operación.

## Consecuencias

### Positivas

- **El datasource retorna datos frescos**: el `AuthUser` retornado refleja exactamente lo que está en Firebase, no una copia local del nombre recién escrito.
- **`reload()` es idempotente y barato**: hace una petición GET ligera al servidor. Si hay problemas de red, lanza `FirebaseAuthException` que el `catch` captura.
- **Comprobación de sesión explícita**: retornar `UnauthorizedFailure` es más informativo que dejar que `currentUser!` explote con un crash.

### Negativas / Trade-offs

- **Dos llamadas de red consecutivas**: `updateDisplayName` + `reload()` implica dos round-trips a Firebase en lugar de uno. En la práctica, ambas son rápidas y el UX no se resiente.
- **`reload()` no está disponible en tests con mocks**: los tests de `FirebaseProfileDatasource` deben mockear `reload()` explícitamente o usar una clase fake de `FirebaseAuth`. El mock de `mockUser.reload()` debe configurarse con `when(() => mockUser.reload()).thenAnswer(...)`.

## Alternativas consideradas

| Alternativa | Descartada porque |
|---|---|
| Retornar `AuthUser` con el nombre pasado como parámetro sin re-leer de Firebase | El `uid` y `email` vendrían del estado anterior, no de Firebase; si hay inconsistencia (ej. email cambiado en paralelo), se retorna un usuario stale |
| Escuchar `authStateChanges()` para detectar el cambio | El stream no emite nuevos eventos solo por `updateDisplayName`; emite solo al sign-in/sign-out |
| `updateProfile(displayName: name)` (API más nueva) | Equivalente; `updateDisplayName` es más explícita sobre qué campo se modifica |
