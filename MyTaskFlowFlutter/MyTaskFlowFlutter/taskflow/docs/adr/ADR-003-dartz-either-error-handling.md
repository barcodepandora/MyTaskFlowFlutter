# ADR-003: dartz Either<Failure, T> para manejo de errores

- **Estado**: Aceptado
- **Fecha**: 2026-06-01
- **Fase**: 0 — Fundación

## Contexto

Los use cases pueden fallar de formas conocidas (credenciales inválidas, tarea no encontrada, error de red). Se necesita una manera de comunicar fallos a la capa de presentación sin:
- Lanzar excepciones que crucen capas (rompe la separación domain ↔ presentation).
- Retornar `null` (ambiguo: ¿fue un error o un resultado vacío válido?).
- Añadir campos `error` opcionales a los modelos de retorno.

## Decisión

Se usa el tipo `Either<Failure, T>` del paquete **dartz** en la firma de todos los use cases y repositorios:

```dart
// Repositorio (domain)
abstract class TaskRepository {
  Future<Either<Failure, TaskEntity>> createTask(TaskEntity task);
  Future<Either<Failure, List<TaskEntity>>> getAllTasks();
}

// Use case
class CreateTaskUseCase {
  Future<Either<Failure, TaskEntity>> call(TaskEntity task) async { ... }
}
```

Jerarquía de `Failure` (sealed class en `core/error/failures.dart`):
- `InvalidCredentialsFailure`
- `TaskNotFoundFailure`
- `TaskValidationFailure`
- `StorageFailure`
- `ServerFailure`
- `UnknownFailure`

La presentación hace fold sobre el resultado:

```dart
result.fold(
  (failure) => state = TasksError(failure.message),
  (task)    => state = TasksLoaded([...tasks, task]),
);
```

## Consecuencias

**Positivas:**
- La firma del método documenta explícitamente que puede fallar.
- No se usan excepciones para flujo de control; los errores de negocio son valores.
- El compilador fuerza a manejar ambos casos (`fold`); no se puede olvidar el error.
- Los tests verifican el tipo de fallo sin try/catch.

**Negativas / trade-offs:**
- `dartz` añade una dependencia externa para un patrón que podría implementarse con un `sealed class Result<T>` propio.
- Desarrolladores sin experiencia en programación funcional encuentran `Either` y `fold` poco intuitivos al principio.
- **Riesgo conocido**: `dartz` no tiene mantenimiento activo reciente. Si el paquete queda abandonado, migrar a un `Result` propio (o a `fpdart`) es el plan B.
