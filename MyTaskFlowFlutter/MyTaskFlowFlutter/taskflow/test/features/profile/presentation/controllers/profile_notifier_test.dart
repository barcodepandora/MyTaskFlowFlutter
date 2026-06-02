import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskflow/core/error/failures.dart';
import 'package:taskflow/features/auth/domain/entities/auth_user.dart';
import 'package:taskflow/features/profile/domain/repositories/profile_repository.dart';
import 'package:taskflow/features/profile/domain/usecases/update_profile_usecase.dart';
import 'package:taskflow/features/profile/presentation/controllers/profile_notifier.dart';
import 'package:taskflow/features/profile/presentation/controllers/profile_state.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late ProfileNotifier notifier;
  late MockProfileRepository mockRepo;

  const tUser = AuthUser(uid: 'uid', email: 'a@b.com', displayName: 'Juan');

  setUp(() {
    mockRepo = MockProfileRepository();
    notifier = ProfileNotifier(UpdateProfileUseCase(mockRepo));
  });

  test('estado inicial es ProfileInitial', () {
    expect(notifier.state, const ProfileInitial());
  });

  test('updateDisplayName éxito → ProfileUpdated con usuario actualizado', () async {
    when(() => mockRepo.updateDisplayName(any()))
        .thenAnswer((_) async => const Right(tUser));

    await notifier.updateDisplayName('Juan');

    expect(notifier.state, const ProfileUpdated(tUser));
  });

  test('updateDisplayName pasa por ProfileLoading antes de resultado', () async {
    final states = <ProfileState>[];
    notifier.addListener(states.add, fireImmediately: false);

    when(() => mockRepo.updateDisplayName(any()))
        .thenAnswer((_) async => const Right(tUser));

    await notifier.updateDisplayName('Juan');

    expect(states.first, const ProfileLoading());
    expect(states.last, const ProfileUpdated(tUser));
  });

  test('updateDisplayName error → ProfileError con mensaje', () async {
    when(() => mockRepo.updateDisplayName(any()))
        .thenAnswer((_) async => const Left(ServerFailure()));

    await notifier.updateDisplayName('Juan');

    expect(notifier.state, isA<ProfileError>());
    expect((notifier.state as ProfileError).message, isNotEmpty);
  });

  test('updateDisplayName error de red → ProfileError con mensaje de red', () async {
    when(() => mockRepo.updateDisplayName(any()))
        .thenAnswer((_) async => const Left(NetworkFailure()));

    await notifier.updateDisplayName('Juan');

    expect(notifier.state, isA<ProfileError>());
  });
}
