import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:taskflow/core/error/failures.dart';
import 'package:taskflow/features/auth/domain/entities/auth_user.dart';
import 'package:taskflow/features/profile/domain/repositories/profile_repository.dart';

class UpdateProfileUseCase {
  const UpdateProfileUseCase(this.repository);

  final ProfileRepository repository;

  Future<Either<Failure, AuthUser>> call(UpdateProfileParams params) {
    return repository.updateDisplayName(params.name);
  }
}

class UpdateProfileParams extends Equatable {
  const UpdateProfileParams({required this.name});

  final String name;

  @override
  List<Object> get props => [name];
}
