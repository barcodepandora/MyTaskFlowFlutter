import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:taskflow/core/error/failures.dart';
import 'package:taskflow/features/auth/domain/entities/auth_user.dart';
import 'package:taskflow/features/profile/domain/repositories/profile_repository.dart';

class FirebaseProfileDatasource implements ProfileRepository {
  FirebaseProfileDatasource(this._firebaseAuth);

  final fb.FirebaseAuth _firebaseAuth;

  @override
  Future<Either<Failure, AuthUser>> updateDisplayName(String name) async {
    try {
      final fbUser = _firebaseAuth.currentUser;
      if (fbUser == null) return const Left(UnauthorizedFailure());
      await fbUser.updateDisplayName(name);
      await fbUser.reload();
      final updated = _firebaseAuth.currentUser!;
      return Right(AuthUser(
        uid: updated.uid,
        email: updated.email ?? '',
        displayName: updated.displayName,
      ));
    } on fb.FirebaseAuthException catch (e) {
      return Left(ServerFailure(e.message ?? 'Error al actualizar perfil'));
    } catch (_) {
      return const Left(ServerFailure('Error inesperado al actualizar perfil.'));
    }
  }
}
