import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskflow/features/profile/data/datasources/firebase_profile_datasource.dart';
import 'package:taskflow/features/profile/domain/repositories/profile_repository.dart';
import 'package:taskflow/features/profile/domain/usecases/update_profile_usecase.dart';
import 'package:taskflow/features/profile/presentation/controllers/profile_notifier.dart';
import 'package:taskflow/features/profile/presentation/controllers/profile_state.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return FirebaseProfileDatasource(fb.FirebaseAuth.instance);
});

final updateProfileUseCaseProvider = Provider<UpdateProfileUseCase>((ref) {
  return UpdateProfileUseCase(ref.watch(profileRepositoryProvider));
});

final profileNotifierProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier(ref.watch(updateProfileUseCaseProvider));
});
