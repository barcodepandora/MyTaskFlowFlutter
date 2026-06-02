import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskflow/features/auth/domain/entities/auth_user.dart';
import 'package:taskflow/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:taskflow/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:taskflow/features/auth/presentation/controllers/auth_state.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier({
    required SignInUseCase signInUseCase,
    required SignOutUseCase signOutUseCase,
  })  : _signInUseCase = signInUseCase,
        _signOutUseCase = signOutUseCase,
        super(const AuthInitial());

  final SignInUseCase _signInUseCase;
  final SignOutUseCase _signOutUseCase;

  Future<void> signIn(String email, String password) async {
    state = const AuthLoading();
    final result = await _signInUseCase(
      SignInParams(email: email, password: password),
    );
    result.fold(
      (failure) => state = AuthError(failure.message),
      (user) => state = AuthAuthenticated(user),
    );
  }

  Future<void> signOut() async {
    await _signOutUseCase();
    state = const AuthUnauthenticated();
  }

  void updateUser(AuthUser user) {
    state = AuthAuthenticated(user);
  }
}
