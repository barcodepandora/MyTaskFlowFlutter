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
