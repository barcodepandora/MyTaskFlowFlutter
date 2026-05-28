import 'package:dartz/dartz.dart' hide Task;

import '../../../../core/error/failures.dart';
import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';

class GetAllTasksUseCase {
  const GetAllTasksUseCase(this._repository);
  final TaskRepository _repository;

  Future<Either<Failure, List<Task>>> call() => _repository.getAllTasks();
}
