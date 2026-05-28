import 'package:dartz/dartz.dart';
import 'package:taskflow/core/error/failures.dart';
import 'package:taskflow/features/auth/domain/entities/auth_user.dart';

abstract class AuthRepository {
  Future<Either<Failure, AuthUser>> signInWithEmailAndPassword(
    String email,
    String password,
  );
  Future<Either<Failure, void>> signOut();
  Stream<AuthUser> get authStateChanges;
}
