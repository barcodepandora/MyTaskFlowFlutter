import 'package:dartz/dartz.dart' hide Task;

import '../../../../core/error/failures.dart';
import '../repositories/task_repository.dart';

class DeleteTaskUseCase {
  const DeleteTaskUseCase(this._repository);
  final TaskRepository _repository;

  Future<Either<Failure, void>> call(String id) => _repository.deleteTask(id);
}
