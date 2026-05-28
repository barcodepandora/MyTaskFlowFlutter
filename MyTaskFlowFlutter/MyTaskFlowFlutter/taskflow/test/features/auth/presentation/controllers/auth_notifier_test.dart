import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskflow/core/error/failures.dart';
import 'package:taskflow/features/auth/domain/entities/auth_user.dart';
import 'package:taskflow/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:taskflow/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:taskflow/features/auth/presentation/controllers/auth_notifier.dart';
import 'package:taskflow/features/auth/presentation/controllers/auth_state.dart';

class MockSignInUseCase extends Mock implements SignInUseCase {}

class MockSignOutUseCase extends Mock implements SignOutUseCase {}

void main() {
  late AuthNotifier notifier;
  late MockSignInUseCase mockSignIn;
  late MockSignOutUseCase mockSignOut;

  const testUser = AuthUser(uid: 'uid-123', email: 'test@taskflow.com');

  setUpAll(() {
    registerFallbackValue(const SignInParams(email: '', password: ''));
  });

  setUp(() {
    mockSignIn = MockSignInUseCase();
    mockSignOut = MockSignOutUseCase();
    notifier = AuthNotifier(
      signInUseCase: mockSignIn,
      signOutUseCase: mockSignOut,
    );
  });

  tearDown(() => notifier.dispose());

  test('initial state is AuthInitial', () {
    expect(notifier.state, isA<AuthInitial>());
  });

  test('signIn with valid credentials → AuthAuthenticated', () async {
    when(() => mockSignIn(any()))
        .thenAnswer((_) async => const Right(testUser));

    await notifier.signIn('test@taskflow.com', 'Test1234!');

    expect(notifier.state, isA<AuthAuthenticated>());
    expect((notifier.state as AuthAuthenticated).user, testUser);
  });

  test('signIn with invalid credentials → AuthError', () async {
    when(() => mockSignIn(any()))
        .thenAnswer((_) async => const Left(InvalidCredentialsFailure()));

    await notifier.signIn('wrong@email.com', 'badpass');

    expect(notifier.state, isA<AuthError>());
    expect((notifier.state as AuthError).message, 'Credenciales inválidas');
  });

  test('signOut → AuthUnauthenticated', () async {
    when(() => mockSignOut())
        .thenAnswer((_) async => const Right(null));

    await notifier.signOut();

    expect(notifier.state, isA<AuthUnauthenticated>());
  });

  test('state passes through AuthLoading before result', () async {
    final states = <AuthState>[];

    when(() => mockSignIn(any())).thenAnswer((_) async {
      await Future.delayed(const Duration(milliseconds: 10));
      return const Right(testUser);
    });

    notifier.addListener(states.add, fireImmediately: false);
    await notifier.signIn('test@taskflow.com', 'Test1234!');

    expect(states.first, isA<AuthLoading>());
    expect(states.last, isA<AuthAuthenticated>());
  });
}
