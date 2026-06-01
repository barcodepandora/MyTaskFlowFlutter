import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  const Failure([this.message = '']);
  final String message;

  @override
  List<Object> get props => [message];
}

class InvalidCredentialsFailure extends Failure {
  const InvalidCredentialsFailure([super.message = 'Credenciales inválidas']);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Error del servidor']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Error desconocido']);
}

class TaskNotFoundFailure extends Failure {
  const TaskNotFoundFailure([super.message = 'Tarea no encontrada']);
}

class TaskValidationFailure extends Failure {
  const TaskValidationFailure([super.message = 'Datos de tarea inválidos']);
}

class StorageFailure extends Failure {
  const StorageFailure([super.message = 'Error de almacenamiento']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Sin conexión. Verifica tu red.']);
}

class UserNotFoundFailure extends Failure {
  const UserNotFoundFailure([super.message = 'Usuario no encontrado']);
}

class TimeoutFailure extends Failure {
  const TimeoutFailure([super.message = 'La solicitud tardó demasiado']);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure(
      [super.message = 'Sesión expirada. Inicia sesión de nuevo']);
}
