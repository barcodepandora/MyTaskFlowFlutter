import 'package:dartz/dartz.dart' hide Task;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskflow/core/error/failures.dart';
import 'package:taskflow/features/tasks/domain/entities/task_entity.dart';
import 'package:taskflow/features/tasks/domain/entities/task_filter.dart';
import 'package:taskflow/features/tasks/domain/entities/task_priority.dart';
import 'package:taskflow/features/tasks/domain/repositories/task_repository.dart';
import 'package:taskflow/features/tasks/domain/usecases/search_tasks_usecase.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  late MockTaskRepository repo;
  late SearchTasksUseCase usecase;

  setUp(() {
    repo = MockTaskRepository();
    usecase = SearchTasksUseCase(repo);
    registerFallbackValue(const TaskFilter());
  });

  test('filters tasks by keyword via repository', () async {
    const filter = TaskFilter(keyword: 'milk');
    when(() => repo.searchTasks(any())).thenAnswer((_) async => const Right([]));
    final result = await usecase(filter);
    expect(result, const Right<Failure, List<Task>>([]));
    verify(() => repo.searchTasks(any())).called(1);
  });

  test('filters by priority', () async {
    const filter = TaskFilter(priority: TaskPriority.urgent);
    when(() => repo.searchTasks(any())).thenAnswer((_) async => const Right([]));
    await usecase(filter);
    verify(() => repo.searchTasks(any())).called(1);
  });

  test('propagates StorageFailure', () async {
    when(() => repo.searchTasks(any()))
        .thenAnswer((_) async => const Left(StorageFailure()));
    final result = await usecase(const TaskFilter());
    expect(result, const Left<Failure, List<Task>>(StorageFailure()));
  });
}
