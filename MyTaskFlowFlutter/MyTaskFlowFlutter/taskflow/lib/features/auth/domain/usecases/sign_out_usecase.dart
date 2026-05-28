import 'package:dartz/dartz.dart';
import 'package:taskflow/core/error/failures.dart';
import 'package:taskflow/features/auth/domain/repositories/auth_repository.dart';

class SignOutUseCase {
  const SignOutUseCase(this.repository);

  final AuthRepository repository;

  Future<Either<Failure, void>> call() {
    return repository.signOut();
  }
}
