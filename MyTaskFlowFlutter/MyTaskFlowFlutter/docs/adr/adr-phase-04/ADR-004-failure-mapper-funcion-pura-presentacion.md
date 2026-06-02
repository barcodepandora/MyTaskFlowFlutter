# ADR-004: `mapFailureToMessage` — función pura centralizada para mensajes de UI

**Estado:** Aceptado  
**Fecha:** 2026-06-01  
**Fase:** Phase 4 — Backend Integration MVP  
**Tags:** presentation, error-handling, failure, ui, pure-function, i18n

---

## Contexto

Con la introducción de Firebase en Phase 4, el catálogo de `Failure` creció de 5 a 9 subclases:

```
InvalidCredentialsFailure  ServerFailure      UnknownFailure
TaskNotFoundFailure        TaskValidationFailure  StorageFailure
NetworkFailure (nueva)     UserNotFoundFailure (nueva)
TimeoutFailure (nueva)     UnauthorizedFailure (nueva)
```

Cada notifier (`AuthNotifier`, `TasksNotifier`) necesita convertir un `Failure` en un `String` legible para el usuario. Sin un punto centralizado, cada notifier haría su propio `switch` duplicando la lógica, y los strings quedarían dispersos por la codebase.

## Decisión

### Función pura `mapFailureToMessage` en `core/utils/failure_mapper.dart`

```dart
String mapFailureToMessage(Failure failure) {
  return switch (failure) {
    NetworkFailure()            => 'Sin conexión. Verifica tu red.',
    UnauthorizedFailure()       => 'Sesión expirada. Inicia sesión de nuevo.',
    ServerFailure()             => 'Error del servidor. Intenta de nuevo.',
    UserNotFoundFailure()       => 'Usuario no encontrado.',
    InvalidCredentialsFailure() => 'Correo o contraseña incorrectos.',
    TimeoutFailure()            => 'La solicitud tardó demasiado. Intenta de nuevo.',
    TaskNotFoundFailure()       => 'Tarea no encontrada.',
    TaskValidationFailure()     => 'Datos de tarea inválidos.',
    StorageFailure()            => 'Error de almacenamiento.',
    UnknownFailure()            => 'Error desconocido. Intenta de nuevo.',
    _                           => failure.message.isNotEmpty
                                     ? failure.message
                                     : 'Error desconocido.',
  };
}
```

Se usa **pattern matching sobre tipos** (`case NetworkFailure()`), no sobre el campo `message`. Esto garantiza que añadir una nueva subclase de `Failure` sin actualizar el switch cause un warning del linter (exhaustiveness check en Dart 3).

El catch-all `_` cubre subclases futuras usando su `message` como fallback.

## Consecuencias

### Positivas

- **Un solo lugar para cambiar strings de error**: si el equipo de producto decide cambiar "Sesión expirada" por "Tu sesión ha vencido", hay exactamente un archivo a modificar.
- **Preparado para i18n**: cuando se añada localización, `mapFailureToMessage` será la única función a reemplazar por una versión que use `AppLocalizations`.
- **Testable de forma aislada**: `mapFailureToMessage(const NetworkFailure())` es una función pura — sus tests no necesitan widgets ni notifiers.
- **Agota el catálogo de Failures**: el switch cubre cada subclase explícitamente. Dart 3 advierte si se añade una subclase sealed sin actualizar el switch.

### Negativas / Trade-offs

- **Contexto de mensaje único**: la función retorna solo un `String` genérico. Casos que requieran un título diferente del body (ej. un `AlertDialog` con título "Error de red" y subtítulo más largo) necesitarían una estructura `{title, body}` en lugar de un string plano.
- **Sin contexto de operación**: el mensaje no sabe si el error ocurrió al crear, al actualizar o al eliminar una tarea; el string es el mismo para cualquier `StorageFailure`. Para MVP es suficiente; refactorizar si el UX exige mensajes más contextuales.

## Alternativas consideradas

| Alternativa | Descartada porque |
|---|---|
| Switch en cada notifier | Duplicación inmediata al tener 3+ notifiers; cada uno puede desincronizarse |
| Método `toMessage()` en `Failure` | El dominio no debe saber cómo presentarse al usuario; los mensajes son responsabilidad de presentación |
| Mapa `Map<Type, String>` | No es exhaustivo en tiempo de compilación; falla en silencio si se omite una subclase |
| Extension method `Failure.toMessage()` | Semánticamente igual que método en la clase; no resuelve el problema de capa |
