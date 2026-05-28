import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskflow/core/error/failures.dart';
import 'package:taskflow/features/auth/domain/repositories/auth_repository.dart';
import 'package:taskflow/features/auth/domain/usecases/sign_out_usecase.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late SignOutUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = SignOutUseCase(mockRepository);
  });

  test('returns Right(void) when repository succeeds', () async {
    when(() => mockRepository.signOut())
        .thenAnswer((_) async => const Right(null));

    final result = await useCase();

    expect(result, const Right(null));
    verify(() => mockRepository.signOut()).called(1);
  });

  test('returns Left(Failure) when repository fails', () async {
    const failure = UnknownFailure();
    when(() => mockRepository.signOut())
        .thenAnswer((_) async => const Left(failure));

    final result = await useCase();

    expect(result, const Left(failure));
  });
}
