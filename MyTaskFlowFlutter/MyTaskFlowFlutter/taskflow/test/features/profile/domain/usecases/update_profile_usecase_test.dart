import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskflow/core/error/failures.dart';
import 'package:taskflow/features/auth/domain/entities/auth_user.dart';
import 'package:taskflow/features/profile/domain/repositories/profile_repository.dart';
import 'package:taskflow/features/profile/domain/usecases/update_profile_usecase.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late UpdateProfileUseCase useCase;
  late MockProfileRepository mockRepo;

  const tUser = AuthUser(uid: 'uid', email: 'a@b.com', displayName: 'Juan');
  const tParams = UpdateProfileParams(name: 'Juan');

  setUp(() {
    mockRepo = MockProfileRepository();
    useCase = UpdateProfileUseCase(mockRepo);
  });

  test('delega al repository con el nombre correcto y retorna Right(AuthUser)', () async {
    when(() => mockRepo.updateDisplayName(any()))
        .thenAnswer((_) async => const Right(tUser));

    final result = await useCase(tParams);

    expect(result, const Right(tUser));
    verify(() => mockRepo.updateDisplayName('Juan')).called(1);
  });

  test('propaga Left(Failure) cuando el repository falla', () async {
    when(() => mockRepo.updateDisplayName(any()))
        .thenAnswer((_) async => const Left(ServerFailure()));

    final result = await useCase(tParams);

    expect(result.isLeft(), true);
  });

  test('UpdateProfileParams igualdad por valor', () {
    const p1 = UpdateProfileParams(name: 'Ana');
    const p2 = UpdateProfileParams(name: 'Ana');
    expect(p1, p2);
  });
}
