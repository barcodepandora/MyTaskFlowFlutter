import 'package:dartz/dartz.dart' hide Task;

import '../../../../core/error/failures.dart';
import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';

class UpdateTaskUseCase {
  const UpdateTaskUseCase(this._repository);
  final TaskRepository _repository;

  Future<Either<Failure, Task>> call(Task task) => _repository.updateTask(task);
}
