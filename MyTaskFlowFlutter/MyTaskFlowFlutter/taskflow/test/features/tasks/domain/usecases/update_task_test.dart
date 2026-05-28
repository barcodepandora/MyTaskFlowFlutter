import 'package:dartz/dartz.dart' hide Task;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskflow/core/error/failures.dart';
import 'package:taskflow/features/tasks/domain/entities/task_entity.dart';
import 'package:taskflow/features/tasks/domain/entities/task_filter.dart';
import 'package:taskflow/features/tasks/domain/entities/task_priority.dart';
import 'package:taskflow/features/tasks/domain/repositories/task_repository.dart';
import 'package:taskflow/features/tasks/domain/usecases/update_task_usecase.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  late MockTaskRepository repo;
  late UpdateTaskUseCase usecase;

  final task = Task(
    id: 'id-1',
    title: 'Updated',
    description: '',
    dueDate: DateTime(2026, 12, 31),
    category: 'Trabajo',
    priority: TaskPriority.high,
    isCompleted: false,
    createdAt: DateTime(2026, 5, 1),
    updatedAt: DateTime(2026, 5, 28),
  );

  setUp(() {
    repo = MockTaskRepository();
    usecase = UpdateTaskUseCase(repo);
    registerFallbackValue(task);
    registerFallbackValue(const TaskFilter());
  });

  test('returns updated task on success', () async {
    when(() => repo.updateTask(any())).thenAnswer((_) async => Right(task));
    final result = await usecase(task);
    expect(result, Right<Failure, Task>(task));
  });

  test('propagates TaskNotFoundFailure', () async {
    when(() => repo.updateTask(any()))
        .thenAnswer((_) async => const Left(TaskNotFoundFailure()));
    final result = await usecase(task);
    expect(result, const Left<Failure, Task>(TaskNotFoundFailure()));
  });
}
