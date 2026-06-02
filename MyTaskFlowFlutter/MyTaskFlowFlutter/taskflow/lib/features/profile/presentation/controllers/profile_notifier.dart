import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskflow/core/utils/failure_mapper.dart';
import 'package:taskflow/features/profile/domain/usecases/update_profile_usecase.dart';
import 'package:taskflow/features/profile/presentation/controllers/profile_state.dart';

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier(this._updateProfileUseCase) : super(const ProfileInitial());

  final UpdateProfileUseCase _updateProfileUseCase;

  Future<void> updateDisplayName(String name) async {
    state = const ProfileLoading();
    final result =
        await _updateProfileUseCase(UpdateProfileParams(name: name));
    result.fold(
      (failure) => state = ProfileError(mapFailureToMessage(failure)),
      (user) => state = ProfileUpdated(user),
    );
  }
}
