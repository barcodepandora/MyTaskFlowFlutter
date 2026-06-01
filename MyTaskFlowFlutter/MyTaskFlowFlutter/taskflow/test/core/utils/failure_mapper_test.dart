import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/core/error/failures.dart';
import 'package:taskflow/core/utils/failure_mapper.dart';

void main() {
  group('mapFailureToMessage', () {
    test('NetworkFailure → sin conexión message', () {
      expect(
        mapFailureToMessage(const NetworkFailure()),
        'Sin conexión. Verifica tu red.',
      );
    });

    test('UnauthorizedFailure → sesión expirada message', () {
      expect(
        mapFailureToMessage(const UnauthorizedFailure()),
        'Sesión expirada. Inicia sesión de nuevo.',
      );
    });

    test('ServerFailure → error del servidor message', () {
      expect(
        mapFailureToMessage(const ServerFailure()),
        'Error del servidor. Intenta de nuevo.',
      );
    });

    test('UserNotFoundFailure → usuario no encontrado message', () {
      expect(
        mapFailureToMessage(const UserNotFoundFailure()),
        'Usuario no encontrado.',
      );
    });

    test('InvalidCredentialsFailure → credenciales incorrectas message', () {
      expect(
        mapFailureToMessage(const InvalidCredentialsFailure()),
        'Correo o contraseña incorrectos.',
      );
    });

    test('TimeoutFailure → timeout message', () {
      expect(
        mapFailureToMessage(const TimeoutFailure()),
        'La solicitud tardó demasiado. Intenta de nuevo.',
      );
    });

    test('TaskNotFoundFailure → tarea no encontrada message', () {
      expect(
        mapFailureToMessage(const TaskNotFoundFailure()),
        'Tarea no encontrada.',
      );
    });

    test('TaskValidationFailure → datos inválidos message', () {
      expect(
        mapFailureToMessage(const TaskValidationFailure()),
        'Datos de tarea inválidos.',
      );
    });

    test('StorageFailure → almacenamiento message', () {
      expect(
        mapFailureToMessage(const StorageFailure()),
        'Error de almacenamiento.',
      );
    });

    test('UnknownFailure → desconocido message', () {
      expect(
        mapFailureToMessage(const UnknownFailure()),
        'Error desconocido. Intenta de nuevo.',
      );
    });

    test('StorageFailure with custom message uses predefined message', () {
      expect(
        mapFailureToMessage(const StorageFailure('Custom error')),
        'Error de almacenamiento.',
      );
    });
  });
}
