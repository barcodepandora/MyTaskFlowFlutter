import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskflow/features/auth/data/datasources/remote_auth_datasource.dart';
import 'package:taskflow/features/auth/domain/repositories/auth_repository.dart';
import 'package:taskflow/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:taskflow/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:taskflow/features/auth/presentation/controllers/auth_notifier.dart';
import 'package:taskflow/features/auth/presentation/controllers/auth_state.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return RemoteAuthDatasource(fb.FirebaseAuth.instance);
});

final signInUseCaseProvider = Provider<SignInUseCase>((ref) {
  return SignInUseCase(ref.watch(authRepositoryProvider));
});

final signOutUseCaseProvider = Provider<SignOutUseCase>((ref) {
  return SignOutUseCase(ref.watch(authRepositoryProvider));
});

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    signInUseCase: ref.watch(signInUseCaseProvider),
    signOutUseCase: ref.watch(signOutUseCaseProvider),
  );
});
