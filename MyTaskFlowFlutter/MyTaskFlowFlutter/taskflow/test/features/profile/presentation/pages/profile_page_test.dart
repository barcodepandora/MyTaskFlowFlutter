import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskflow/core/error/failures.dart';
import 'package:taskflow/core/providers/theme_provider.dart';
import 'package:taskflow/features/auth/data/providers/auth_providers.dart';
import 'package:taskflow/features/auth/domain/entities/auth_user.dart';
import 'package:taskflow/features/auth/domain/repositories/auth_repository.dart';
import 'package:taskflow/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:taskflow/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:taskflow/features/auth/presentation/controllers/auth_notifier.dart';
import 'package:taskflow/features/auth/presentation/controllers/auth_state.dart';
import 'package:taskflow/features/profile/data/providers/profile_providers.dart';
import 'package:taskflow/features/profile/domain/repositories/profile_repository.dart';
import 'package:taskflow/features/profile/domain/usecases/update_profile_usecase.dart';
import 'package:taskflow/features/profile/presentation/controllers/profile_notifier.dart';
import 'package:taskflow/features/profile/presentation/controllers/profile_state.dart';
import 'package:taskflow/features/profile/presentation/pages/profile_page.dart';

// ─── Fakes ────────────────────────────────────────────────────────────────────

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

class _FakeAuthNotifier extends AuthNotifier {
  _FakeAuthNotifier()
      : super(
          signInUseCase: SignInUseCase(_AlwaysFailAuthRepo()),
          signOutUseCase: SignOutUseCase(_AlwaysFailAuthRepo()),
        );

  void forceState(AuthState s) => state = s;
}

class _AlwaysFailAuthRepo implements AuthRepository {
  @override
  Future<Either<Failure, AuthUser>> signInWithEmailAndPassword(
          String email, String password) async =>
      const Left(InvalidCredentialsFailure());
  @override
  Future<Either<Failure, void>> signOut() async => const Right(null);
  @override
  Stream<AuthUser> get authStateChanges => const Stream.empty();
}

class _FakeProfileNotifier extends ProfileNotifier {
  _FakeProfileNotifier(ProfileRepository repo)
      : super(UpdateProfileUseCase(repo));

  void forceState(ProfileState s) => state = s;
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

const tUser = AuthUser(uid: 'uid', email: 'test@test.com', displayName: 'Juan');

Future<Widget> _buildPage({
  ProfileRepository? profileRepo,
  AuthUser user = tUser,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final repo = profileRepo ?? MockProfileRepository();

  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      authNotifierProvider.overrideWith((_) {
        return _FakeAuthNotifier()..forceState(AuthAuthenticated(user));
      }),
      profileNotifierProvider.overrideWith((_) => _FakeProfileNotifier(repo)),
    ],
    child: const MaterialApp(home: ProfilePage()),
  );
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('ProfilePage', () {
    testWidgets('muestra email del usuario autenticado', (tester) async {
      await tester.pumpWidget(await _buildPage());
      await tester.pumpAndSettle();

      expect(find.text('test@test.com'), findsOneWidget);
    });

    testWidgets('campo displayName pre-relleno con nombre actual', (tester) async {
      await tester.pumpWidget(await _buildPage());
      await tester.pumpAndSettle();

      final field = tester.widget<TextFormField>(
        find.byKey(const Key('displayNameField')),
      );
      expect(field.controller?.text, 'Juan');
    });

    testWidgets('muestra botón Guardar cambios', (tester) async {
      await tester.pumpWidget(await _buildPage());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('saveProfileButton')), findsOneWidget);
    });

    testWidgets('muestra SegmentedButton de tema', (tester) async {
      await tester.pumpWidget(await _buildPage());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('themeModeButton')), findsOneWidget);
      expect(find.text('Claro'), findsOneWidget);
      expect(find.text('Oscuro'), findsOneWidget);
      expect(find.text('Sistema'), findsOneWidget);
    });

    testWidgets('muestra botón Cerrar sesión', (tester) async {
      await tester.pumpWidget(await _buildPage());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('signOutButton')), findsOneWidget);
    });

    testWidgets('validación: campo vacío muestra error', (tester) async {
      await tester.pumpWidget(await _buildPage());
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('displayNameField')), '');
      await tester.tap(find.byKey(const Key('saveProfileButton')));
      await tester.pump();

      expect(find.text('Ingresa tu nombre'), findsOneWidget);
    });

    testWidgets('guarda correctamente y muestra SnackBar de éxito', (tester) async {
      final repo = MockProfileRepository();
      when(() => repo.updateDisplayName(any()))
          .thenAnswer((_) async => const Right(
                AuthUser(uid: 'uid', email: 'test@test.com', displayName: 'Juan Nuevo'),
              ));

      await tester.pumpWidget(await _buildPage(profileRepo: repo));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('displayNameField')), 'Juan Nuevo');
      await tester.tap(find.byKey(const Key('saveProfileButton')));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Perfil actualizado'), findsOneWidget);
    });

    testWidgets('muestra SnackBar con error cuando falla el guardado', (tester) async {
      final repo = MockProfileRepository();
      when(() => repo.updateDisplayName(any()))
          .thenAnswer((_) async => const Left(ServerFailure()));

      await tester.pumpWidget(await _buildPage(profileRepo: repo));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('saveProfileButton')));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
