import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:taskflow/core/error/failures.dart';
import 'package:taskflow/features/auth/data/providers/auth_providers.dart';
import 'package:taskflow/features/auth/domain/entities/auth_user.dart';
import 'package:taskflow/features/auth/domain/repositories/auth_repository.dart';
import 'package:taskflow/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:taskflow/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:taskflow/features/auth/presentation/controllers/auth_notifier.dart';
import 'package:taskflow/features/auth/presentation/controllers/auth_state.dart';
import 'package:taskflow/features/auth/presentation/pages/login_page.dart';

// ─── Fakes ───────────────────────────────────────────────────────────────────

class _AlwaysSucceedRepo implements AuthRepository {
  @override
  Future<Either<Failure, AuthUser>> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return const Right(AuthUser(uid: 'test-uid', email: 'test@test.com'));
  }

  @override
  Future<Either<Failure, void>> signOut() async => const Right(null);

  @override
  Stream<AuthUser> get authStateChanges => const Stream.empty();
}

class _AlwaysFailRepo implements AuthRepository {
  @override
  Future<Either<Failure, AuthUser>> signInWithEmailAndPassword(
    String email,
    String password,
  ) async =>
      const Left(InvalidCredentialsFailure());

  @override
  Future<Either<Failure, void>> signOut() async => const Right(null);

  @override
  Stream<AuthUser> get authStateChanges => const Stream.empty();
}

class _SuccessFakeNotifier extends AuthNotifier {
  _SuccessFakeNotifier()
      : super(
          signInUseCase: SignInUseCase(_AlwaysSucceedRepo()),
          signOutUseCase: SignOutUseCase(_AlwaysSucceedRepo()),
        );

  void forceState(AuthState s) => state = s;
}

class _FailFakeNotifier extends AuthNotifier {
  _FailFakeNotifier()
      : super(
          signInUseCase: SignInUseCase(_AlwaysFailRepo()),
          signOutUseCase: SignOutUseCase(_AlwaysFailRepo()),
        );
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

Widget _buildTestWidget({
  required AuthNotifier Function() notifierFactory,
}) {
  final router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const Scaffold(body: Text('Home')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      authNotifierProvider.overrideWith((_) => notifierFactory()),
    ],
    child: MaterialApp.router(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      routerConfig: router,
    ),
  );
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('LoginPage', () {
    testWidgets('muestra campos email, password y botón Login', (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(notifierFactory: _SuccessFakeNotifier.new),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('emailField')), findsOneWidget);
      expect(find.byKey(const Key('passwordField')), findsOneWidget);
      expect(find.byKey(const Key('loginButton')), findsOneWidget);
      expect(find.text('TaskFlow'), findsOneWidget);
    });

    testWidgets('muestra error si email inválido al submit', (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(notifierFactory: _SuccessFakeNotifier.new),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('emailField')), 'notanemail');
      await tester.tap(find.byKey(const Key('loginButton')));
      await tester.pump();

      expect(find.text('Email inválido'), findsOneWidget);
    });

    testWidgets('muestra error si password vacío al submit', (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(notifierFactory: _SuccessFakeNotifier.new),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('emailField')), 'test@test.com');
      await tester.tap(find.byKey(const Key('loginButton')));
      await tester.pump();

      expect(find.text('Contraseña requerida'), findsOneWidget);
    });

    testWidgets('muestra loading indicator durante signIn', (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(notifierFactory: _SuccessFakeNotifier.new),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('emailField')), 'test@test.com');
      await tester.enterText(
          find.byKey(const Key('passwordField')), 'password123');

      await tester.tap(find.byKey(const Key('loginButton')));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byKey(const Key('loginButton')), findsNothing);

      await tester.pumpAndSettle();
    });

    testWidgets('navega a /home cuando login es exitoso', (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(notifierFactory: _SuccessFakeNotifier.new),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('emailField')), 'test@test.com');
      await tester.enterText(
          find.byKey(const Key('passwordField')), 'password123');
      await tester.tap(find.byKey(const Key('loginButton')));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('muestra SnackBar con mensaje de error en credenciales inválidas',
        (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(notifierFactory: _FailFakeNotifier.new),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('emailField')), 'wrong@test.com');
      await tester.enterText(
          find.byKey(const Key('passwordField')), 'badpassword');
      await tester.tap(find.byKey(const Key('loginButton')));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Credenciales inválidas'), findsOneWidget);
    });
  });
}
