# ADR-002: `RemoteAuthDatasource` — mapeo de `FirebaseAuthException` a `Failure` jerárquico

**Estado:** Aceptado  
**Fecha:** 2026-06-01  
**Fase:** Phase 4 — Backend Integration MVP  
**Tags:** auth, firebase, error-handling, failure, pattern-matching

---

## Contexto

`FirebaseAuth` lanza `FirebaseAuthException` con un campo `code` (string) cuando falla una operación. Los códigos son específicos del SDK de Firebase y no forman parte del dominio de la aplicación.

La capa de dominio (`AuthRepository`) retorna `Either<Failure, T>` — un tipo de error propio. El problema de diseño es **dónde y cómo convertir** los `FirebaseAuthException` en instancias de `Failure`.

Opciones evaluadas:
- En la capa de presentación (`AuthNotifier`), capturando y convirtiendo allí
- En el datasource, con un método privado de mapeo
- En una función/clase utilitaria compartida en `core/`
- En el repositorio (si existiera una clase `AuthRepositoryImpl`)

## Decisión

### Método privado `_mapAuthException` dentro de `RemoteAuthDatasource`

```dart
Failure _mapAuthException(fb.FirebaseAuthException e) {
  return switch (e.code) {
    'user-not-found' || 'email-not-found'         => const UserNotFoundFailure(),
    'wrong-password'      ||
    'invalid-credential'  ||
    'INVALID_LOGIN_CREDENTIALS' ||
    'invalid-login-credentials'                   => const InvalidCredentialsFailure(),
    'operation-not-allowed' =>
        const ServerFailure('Método de acceso no habilitado en Firebase.'),
    'user-disabled'         =>
        const ServerFailure('Esta cuenta ha sido deshabilitada.'),
    'network-request-failed'                      => const NetworkFailure(),
    'too-many-requests'     =>
        const ServerFailure('Demasiados intentos. Intenta más tarde.'),
    _                       =>
        UnknownFailure(e.message ?? 'Error de autenticación'),
  };
}
```

El método se invoca desde el bloque `catch` de `signInWithEmailAndPassword`:

```dart
} on fb.FirebaseAuthException catch (e) {
  return Left(_mapAuthException(e));
} catch (_) {
  return const Left(ServerFailure('Error inesperado al iniciar sesión.'));
}
```

Se usan **pattern matching con OR-patterns** (`||`) para agrupar códigos sinónimos que Firebase emite según versión del SDK (ej. `'invalid-credential'` vs `'INVALID_LOGIN_CREDENTIALS'`).

## Consecuencias

### Positivas

- **El dominio permanece puro**: `AuthRepository`, `AuthUser` y los use cases nunca ven `FirebaseAuthException`.
- **Agrupación de códigos sinónimos**: Firebase tiene inconsistencias entre plataformas y versiones SDK (mayúsculas, guiones). El OR-pattern centraliza estas variantes en un solo lugar.
- **El bloque `catch (_)` como red de seguridad**: errores inesperados no propagados como excepciones sin manejar — siempre retornan un `Left` controlado.
- **Testabilidad**: se pueden probar los mapeos pasando un `FirebaseAuthException` con distintos `code` — sin necesidad de levantar Firebase real.

### Negativas / Trade-offs

- **Lógica de mapeo acoplada al datasource**: si otro datasource de auth (OAuth, biometría) produce errores similares, no puede reutilizar `_mapAuthException` directamente. Aceptable para MVP; refactorizar a `AuthExceptionMapper` compartido si se añaden más proveedores de auth.
- **Mantenimiento de códigos Firebase**: Firebase puede deprecar o añadir códigos en futuras versiones del SDK. Requiere revisión al actualizar `firebase_auth`.

## Alternativas consideradas

| Alternativa | Descartada porque |
|---|---|
| Capturar en `AuthNotifier` | La presentación no debe conocer `FirebaseAuthException`; rompe la separación de capas |
| `AuthExceptionMapper` en `core/` | Abstracción prematura con un solo datasource de auth; crear cuando haya múltiples proveedores |
| Usar solo el mensaje `e.message` | Los mensajes de Firebase están en inglés y son inconsistentes; perder la semántica de tipo de error |
| Lanzar y relanzar la excepción | Rompe el contrato `Either<Failure, T>` del repositorio; la capa superior esperaría manejar excepciones en lugar de `Left` |
