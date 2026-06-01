import 'package:dartz/dartz.dart' hide Task;

import '../../../../core/error/failures.dart';
import '../../../tasks/domain/repositories/task_repository.dart';
import '../entities/task_stats.dart';

class GetDashboardStatsUseCase {
  const GetDashboardStatsUseCase(this._repository);
  final TaskRepository _repository;

  Future<Either<Failure, TaskStats>> call() async {
    final result = await _repository.getAllTasks();
    return result.map(TaskStats.fromList);
  }
}
