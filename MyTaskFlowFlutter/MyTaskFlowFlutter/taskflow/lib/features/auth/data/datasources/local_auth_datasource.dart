import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:taskflow/core/error/failures.dart';
import 'package:taskflow/features/auth/domain/entities/auth_user.dart';
import 'package:taskflow/features/auth/domain/repositories/auth_repository.dart';

class LocalAuthDatasource implements AuthRepository {
  static const _validEmail = 'test@taskflow.com';
  static const _validPassword = 'Test1234!';

  final _authStateController = StreamController<AuthUser>.broadcast();

  @override
  Stream<AuthUser> get authStateChanges => _authStateController.stream;

  @override
  Future<Either<Failure, AuthUser>> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (email == _validEmail && password == _validPassword) {
      const user = AuthUser(
        uid: 'local-user-uid',
        email: _validEmail,
        displayName: 'Test User',
      );
      _authStateController.add(user);
      return const Right(user);
    }
    return const Left(InvalidCredentialsFailure());
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    _authStateController.add(AuthUser.empty());
    return const Right(null);
  }

  void dispose() => _authStateController.close();
}
