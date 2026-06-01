import 'package:dartz/dartz.dart' hide Task;

import '../../../../core/error/failures.dart';
import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';

class CreateTaskUseCase {
  const CreateTaskUseCase(this._repository);
  final TaskRepository _repository;

  Future<Either<Failure, Task>> call(Task task) {
    if (task.title.trim().isEmpty) {
      return Future.value(const Left(TaskValidationFailure('El título es requerido')));
    }
    return _repository.createTask(task);
  }
}
