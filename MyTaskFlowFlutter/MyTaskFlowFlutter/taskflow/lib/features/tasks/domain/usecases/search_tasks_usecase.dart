import 'package:dartz/dartz.dart' hide Task;

import '../../../../core/error/failures.dart';
import '../entities/task_entity.dart';
import '../entities/task_filter.dart';
import '../repositories/task_repository.dart';

class SearchTasksUseCase {
  const SearchTasksUseCase(this._repository);
  final TaskRepository _repository;

  Future<Either<Failure, List<Task>>> call(TaskFilter filter) =>
      _repository.searchTasks(filter);
}
