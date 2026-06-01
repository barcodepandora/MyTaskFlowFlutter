import 'package:taskflow/core/error/failures.dart';

String mapFailureToMessage(Failure failure) {
  return switch (failure) {
    NetworkFailure() => 'Sin conexión. Verifica tu red.',
    UnauthorizedFailure() => 'Sesión expirada. Inicia sesión de nuevo.',
    ServerFailure() => 'Error del servidor. Intenta de nuevo.',
    UserNotFoundFailure() => 'Usuario no encontrado.',
    InvalidCredentialsFailure() => 'Correo o contraseña incorrectos.',
    TimeoutFailure() => 'La solicitud tardó demasiado. Intenta de nuevo.',
    TaskNotFoundFailure() => 'Tarea no encontrada.',
    TaskValidationFailure() => 'Datos de tarea inválidos.',
    StorageFailure() => 'Error de almacenamiento.',
    UnknownFailure() => 'Error desconocido. Intenta de nuevo.',
    _ => failure.message.isNotEmpty ? failure.message : 'Error desconocido.',
  };
}
