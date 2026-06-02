import 'package:dartz/dartz.dart';
import 'package:taskflow/core/error/failures.dart';
import 'package:taskflow/features/auth/domain/entities/auth_user.dart';

abstract class ProfileRepository {
  Future<Either<Failure, AuthUser>> updateDisplayName(String name);
}
