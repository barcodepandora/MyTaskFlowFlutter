import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/core/utils/validators.dart';

void main() {
  group('emailValidator', () {
    test('returns error when null', () {
      expect(emailValidator(null), 'Email requerido');
    });

    test('returns error when empty', () {
      expect(emailValidator(''), 'Email requerido');
    });

    test('returns error when invalid format', () {
      expect(emailValidator('notanemail'), 'Email inválido');
      expect(emailValidator('missing@dot'), 'Email inválido');
      expect(emailValidator('@nodomain.com'), 'Email inválido');
    });

    test('returns null for valid email', () {
      expect(emailValidator('user@example.com'), isNull);
      expect(emailValidator('test@taskflow.com'), isNull);
    });
  });

  group('passwordValidator', () {
    test('returns error when null', () {
      expect(passwordValidator(null), 'Contraseña requerida');
    });

    test('returns error when empty', () {
      expect(passwordValidator(''), 'Contraseña requerida');
    });

    test('returns error when less than 6 chars', () {
      expect(passwordValidator('12345'), 'Mínimo 6 caracteres');
    });

    test('returns null for valid password', () {
      expect(passwordValidator('123456'), isNull);
      expect(passwordValidator('Test1234!'), isNull);
    });
  });
}
