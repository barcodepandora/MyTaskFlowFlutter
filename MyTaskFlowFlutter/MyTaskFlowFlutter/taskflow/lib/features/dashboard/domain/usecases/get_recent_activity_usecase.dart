import 'package:dartz/dartz.dart' hide Task;

import '../../../../core/error/failures.dart';
import '../../../tasks/domain/entities/task_entity.dart';
import '../../../tasks/domain/repositories/task_repository.dart';

class GetRecentActivityUseCase {
  const GetRecentActivityUseCase(this._repository);
  final TaskRepository _repository;

  Future<Either<Failure, List<Task>>> call({int maxItems = 5}) async {
    final result = await _repository.getAllTasks();
    return result.map((tasks) {
      final sorted = [...tasks]
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return sorted.take(maxItems).toList();
    });
  }
}
