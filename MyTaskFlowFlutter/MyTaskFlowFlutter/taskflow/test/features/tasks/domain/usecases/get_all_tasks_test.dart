import 'package:dartz/dartz.dart' hide Task;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskflow/core/error/failures.dart';
import 'package:taskflow/features/tasks/domain/entities/task_entity.dart';
import 'package:taskflow/features/tasks/domain/entities/task_filter.dart';
import 'package:taskflow/features/tasks/domain/repositories/task_repository.dart';
import 'package:taskflow/features/tasks/domain/usecases/get_all_tasks_usecase.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  late MockTaskRepository repo;
  late GetAllTasksUseCase usecase;

  setUp(() {
    repo = MockTaskRepository();
    usecase = GetAllTasksUseCase(repo);
    registerFallbackValue(const TaskFilter());
  });

  test('returns task list on success', () async {
    when(() => repo.getAllTasks()).thenAnswer((_) async => const Right([]));
    final result = await usecase();
    expect(result, const Right<Failure, List<Task>>([]));
  });

  test('propagates Failure from repository', () async {
    when(() => repo.getAllTasks())
        .thenAnswer((_) async => const Left(StorageFailure()));
    final result = await usecase();
    expect(result, const Left<Failure, List<Task>>(StorageFailure()));
  });
}
