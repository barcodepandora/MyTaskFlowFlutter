import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskflow/core/error/failures.dart';
import 'package:taskflow/features/profile/data/datasources/firebase_profile_datasource.dart';

import '../../../../helpers/firebase_mocks.dart';

class _MockFirebaseAuthException extends fb.FirebaseAuthException {
  _MockFirebaseAuthException(String code)
      : super(code: code, message: 'Error $code');
}

void main() {
  late FirebaseProfileDatasource datasource;
  late MockFirebaseAuth mockAuth;
  late MockFirebaseUser mockUser;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockUser = MockFirebaseUser();
    datasource = FirebaseProfileDatasource(mockAuth);
  });

  group('updateDisplayName', () {
    test('retorna Right(AuthUser) cuando Firebase actualiza correctamente', () async {
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.updateDisplayName(any())).thenAnswer((_) async {});
      when(() => mockUser.reload()).thenAnswer((_) async {});
      when(() => mockUser.uid).thenReturn('uid-1');
      when(() => mockUser.email).thenReturn('test@test.com');
      when(() => mockUser.displayName).thenReturn('Nuevo Nombre');

      final result = await datasource.updateDisplayName('Nuevo Nombre');

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('expected Right'),
        (user) {
          expect(user.uid, 'uid-1');
          expect(user.displayName, 'Nuevo Nombre');
        },
      );
    });

    test('retorna Left(UnauthorizedFailure) cuando no hay usuario autenticado', () async {
      when(() => mockAuth.currentUser).thenReturn(null);

      final result = await datasource.updateDisplayName('Nombre');

      expect(result, const Left(UnauthorizedFailure()));
    });

    test('retorna Left(ServerFailure) ante FirebaseAuthException', () async {
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.updateDisplayName(any()))
          .thenThrow(_MockFirebaseAuthException('requires-recent-login'));

      final result = await datasource.updateDisplayName('Nombre');

      expect(result.isLeft(), true);
      result.fold(
        (f) => expect(f, isA<ServerFailure>()),
        (_) => fail('expected Left'),
      );
    });

    test('retorna Left(ServerFailure) ante excepción genérica', () async {
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.updateDisplayName(any()))
          .thenThrow(Exception('network error'));

      final result = await datasource.updateDisplayName('Nombre');

      expect(result, const Left(ServerFailure('Error inesperado al actualizar perfil.')));
    });
  });
}
