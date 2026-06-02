import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskflow/core/error/failures.dart';
import 'package:taskflow/features/auth/data/datasources/remote_auth_datasource.dart';
import 'package:taskflow/features/auth/domain/entities/auth_user.dart';

import '../../../../helpers/firebase_mocks.dart';

void main() {
  late MockFirebaseAuth mockAuth;
  late MockUserCredential mockCredential;
  late MockFirebaseUser mockUser;
  late RemoteAuthDatasource datasource;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockCredential = MockUserCredential();
    mockUser = MockFirebaseUser();
    datasource = RemoteAuthDatasource(mockAuth, FakeNetworkInfo(connected: true));
  });

  group('signInWithEmailAndPassword', () {
    test('returns Right(AuthUser) on successful sign in', () async {
      when(() => mockUser.uid).thenReturn('uid-123');
      when(() => mockUser.email).thenReturn('test@taskflow.com');
      when(() => mockUser.displayName).thenReturn('Test User');
      when(() => mockCredential.user).thenReturn(mockUser);
      when(() => mockAuth.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => mockCredential);

      final result = await datasource.signInWithEmailAndPassword(
        'test@taskflow.com',
        'Test1234!',
      );

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Expected Right'), (user) {
        expect(user.uid, 'uid-123');
        expect(user.email, 'test@taskflow.com');
        expect(user.displayName, 'Test User');
        expect(user.isAuthenticated, isTrue);
      });
    });

    test('returns Left(InvalidCredentialsFailure) on wrong-password', () async {
      when(() => mockAuth.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(fb.FirebaseAuthException(code: 'wrong-password'));

      final result = await datasource.signInWithEmailAndPassword(
        'test@taskflow.com',
        'wrong',
      );

      expect(result, const Left(InvalidCredentialsFailure()));
    });

    test('returns Left(InvalidCredentialsFailure) on invalid-credential',
        () async {
      when(() => mockAuth.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(fb.FirebaseAuthException(code: 'invalid-credential'));

      final result = await datasource.signInWithEmailAndPassword(
        'test@taskflow.com',
        'wrong',
      );

      expect(result, const Left(InvalidCredentialsFailure()));
    });

    test('returns Left(UserNotFoundFailure) when user does not exist',
        () async {
      when(() => mockAuth.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(fb.FirebaseAuthException(code: 'user-not-found'));

      final result = await datasource.signInWithEmailAndPassword(
        'nope@test.com',
        'pass',
      );

      expect(result, const Left(UserNotFoundFailure()));
    });

    test('returns Left(NetworkFailure) on network-request-failed', () async {
      when(() => mockAuth.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(
              fb.FirebaseAuthException(code: 'network-request-failed'));

      final result = await datasource.signInWithEmailAndPassword(
        'test@taskflow.com',
        'pass',
      );

      expect(result, const Left(NetworkFailure()));
    });

    test('returns Left(ServerFailure) on too-many-requests', () async {
      when(() => mockAuth.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(fb.FirebaseAuthException(code: 'too-many-requests'));

      final result = await datasource.signInWithEmailAndPassword(
        'test@taskflow.com',
        'pass',
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<ServerFailure>()),
        (_) => fail('Expected Left'),
      );
    });
  });

  group('signOut', () {
    test('calls firebaseAuth.signOut() and returns Right(null)', () async {
      when(() => mockAuth.signOut()).thenAnswer((_) async {});

      final result = await datasource.signOut();

      expect(result, const Right(null));
      verify(() => mockAuth.signOut()).called(1);
    });
  });

  group('authStateChanges', () {
    test('emits authenticated AuthUser when user is signed in', () async {
      when(() => mockUser.uid).thenReturn('uid-123');
      when(() => mockUser.email).thenReturn('test@taskflow.com');
      when(() => mockUser.displayName).thenReturn(null);
      when(() => mockAuth.authStateChanges())
          .thenAnswer((_) => Stream.value(mockUser));

      final users = await datasource.authStateChanges.toList();

      expect(users.length, 1);
      expect(users.first.isAuthenticated, isTrue);
      expect(users.first.uid, 'uid-123');
    });

    test('emits AuthUser.empty() when signed out', () async {
      when(() => mockAuth.authStateChanges())
          .thenAnswer((_) => Stream.value(null));

      final users = await datasource.authStateChanges.toList();

      expect(users.length, 1);
      expect(users.first, AuthUser.empty());
      expect(users.first.isAuthenticated, isFalse);
    });
  });

  group('network failure', () {
    late RemoteAuthDatasource offlineDatasource;

    setUp(() {
      offlineDatasource =
          RemoteAuthDatasource(mockAuth, FakeNetworkInfo(connected: false));
    });

    test('signIn returns NetworkFailure when offline without calling Firebase',
        () async {
      final result = await offlineDatasource.signInWithEmailAndPassword(
        'test@taskflow.com',
        'Test1234!',
      );

      expect(result, const Left(NetworkFailure()));
      verifyNever(() => mockAuth.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ));
    });
  });
}
