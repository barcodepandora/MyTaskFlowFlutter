import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskflow/core/error/failures.dart';
import 'package:taskflow/features/auth/domain/entities/auth_user.dart';
import 'package:taskflow/features/auth/domain/repositories/auth_repository.dart';
import 'package:taskflow/features/auth/domain/usecases/sign_in_usecase.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late SignInUseCase useCase;
  late MockAuthRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(const SignInParams(email: '', password: ''));
  });

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = SignInUseCase(mockRepository);
  });

  const testParams = SignInParams(
    email: 'test@taskflow.com',
    password: 'Test1234!',
  );
  const testUser = AuthUser(uid: 'uid-123', email: 'test@taskflow.com');

  test('returns Right(AuthUser) when repository succeeds', () async {
    when(() => mockRepository.signInWithEmailAndPassword(any(), any()))
        .thenAnswer((_) async => const Right(testUser));

    final result = await useCase(testParams);

    expect(result, const Right(testUser));
    verify(() => mockRepository.signInWithEmailAndPassword(
          testParams.email,
          testParams.password,
        )).called(1);
  });

  test('returns Left(Failure) when repository fails', () async {
    const failure = InvalidCredentialsFailure();
    when(() => mockRepository.signInWithEmailAndPassword(any(), any()))
        .thenAnswer((_) async => const Left(failure));

    final result = await useCase(testParams);

    expect(result, const Left(failure));
  });

  test('calls repository exactly once with correct params', () async {
    when(() => mockRepository.signInWithEmailAndPassword(any(), any()))
        .thenAnswer((_) async => const Right(testUser));

    await useCase(testParams);

    verify(() => mockRepository.signInWithEmailAndPassword(
          'test@taskflow.com',
          'Test1234!',
        )).called(1);
    verifyNoMoreInteractions(mockRepository);
  });
}
