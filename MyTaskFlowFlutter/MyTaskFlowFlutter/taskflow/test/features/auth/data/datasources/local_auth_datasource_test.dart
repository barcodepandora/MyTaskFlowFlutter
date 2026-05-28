import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/core/error/failures.dart';
import 'package:taskflow/features/auth/data/datasources/local_auth_datasource.dart';
import 'package:taskflow/features/auth/domain/entities/auth_user.dart';

void main() {
  late LocalAuthDatasource datasource;

  setUp(() {
    datasource = LocalAuthDatasource();
  });

  tearDown(() {
    datasource.dispose();
  });

  group('signInWithEmailAndPassword', () {
    test('returns Right(AuthUser) with valid credentials', () async {
      final result = await datasource.signInWithEmailAndPassword(
        'test@taskflow.com',
        'Test1234!',
      );

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected Right'),
        (user) {
          expect(user.uid, isNotEmpty);
          expect(user.email, 'test@taskflow.com');
          expect(user.isAuthenticated, isTrue);
        },
      );
    });

    test('returns Left(InvalidCredentialsFailure) with wrong email', () async {
      final result = await datasource.signInWithEmailAndPassword(
        'wrong@email.com',
        'Test1234!',
      );

      expect(result, const Left(InvalidCredentialsFailure()));
    });

    test('returns Left(InvalidCredentialsFailure) with wrong password', () async {
      final result = await datasource.signInWithEmailAndPassword(
        'test@taskflow.com',
        'wrongpass',
      );

      expect(result, const Left(InvalidCredentialsFailure()));
    });
  });

  group('signOut', () {
    test('returns Right(null) and emits empty user on stream', () async {
      await datasource.signInWithEmailAndPassword(
        'test@taskflow.com',
        'Test1234!',
      );

      final events = <AuthUser>[];
      final subscription = datasource.authStateChanges.listen(events.add);

      final result = await datasource.signOut();

      await Future.delayed(Duration.zero);
      expect(result, const Right(null));
      expect(events.last.isAuthenticated, isFalse);

      await subscription.cancel();
    });
  });

  group('authStateChanges', () {
    test('emits AuthUser on successful signIn', () async {
      final events = <AuthUser>[];
      final subscription = datasource.authStateChanges.listen(events.add);

      await datasource.signInWithEmailAndPassword(
        'test@taskflow.com',
        'Test1234!',
      );

      await Future.delayed(Duration.zero);
      expect(events, isNotEmpty);
      expect(events.last.isAuthenticated, isTrue);

      await subscription.cancel();
    });
  });
}
