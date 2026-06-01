import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:taskflow/core/error/failures.dart';
import 'package:taskflow/features/auth/domain/entities/auth_user.dart';
import 'package:taskflow/features/auth/domain/repositories/auth_repository.dart';

class RemoteAuthDatasource implements AuthRepository {
  RemoteAuthDatasource(this._firebaseAuth);

  final fb.FirebaseAuth _firebaseAuth;

  @override
  Stream<AuthUser> get authStateChanges {
    return _firebaseAuth.authStateChanges().map(
          (user) => user == null
              ? AuthUser.empty()
              : AuthUser(
                  uid: user.uid,
                  email: user.email ?? '',
                  displayName: user.displayName,
                ),
        );
  }

  @override
  Future<Either<Failure, AuthUser>> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user!;
      return Right(AuthUser(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
      ));
    } on fb.FirebaseAuthException catch (e) {
      return Left(_mapAuthException(e));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await _firebaseAuth.signOut();
      return const Right(null);
    } on fb.FirebaseAuthException catch (e) {
      return Left(ServerFailure(e.message ?? 'Error al cerrar sesión'));
    }
  }

  Failure _mapAuthException(fb.FirebaseAuthException e) {
    return switch (e.code) {
      'user-not-found' => const UserNotFoundFailure(),
      'wrong-password' || 'invalid-credential' =>
        const InvalidCredentialsFailure(),
      'network-request-failed' => const NetworkFailure(),
      'too-many-requests' =>
        const ServerFailure('Demasiados intentos. Intenta más tarde.'),
      _ => UnknownFailure(e.message ?? 'Error de autenticación'),
    };
  }
}
