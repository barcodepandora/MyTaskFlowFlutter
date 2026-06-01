import 'package:dartz/dartz.dart' hide Task;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskflow/core/error/failures.dart';
import 'package:taskflow/features/tasks/domain/entities/task_entity.dart';
import 'package:taskflow/features/tasks/domain/entities/task_filter.dart';
import 'package:taskflow/features/tasks/domain/entities/task_priority.dart';
import 'package:taskflow/features/tasks/domain/repositories/task_repository.dart';
import 'package:taskflow/features/tasks/domain/usecases/create_task_usecase.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  late MockTaskRepository repo;
  late CreateTaskUseCase usecase;

  final validTask = Task(
    id: 'id-1',
    title: 'Buy milk',
    description: '',
    dueDate: DateTime(2026, 12, 31),
    category: 'Personal',
    priority: TaskPriority.low,
    isCompleted: false,
    createdAt: DateTime(2026, 5, 1),
    updatedAt: DateTime(2026, 5, 1),
  );

  setUp(() {
    repo = MockTaskRepository();
    usecase = CreateTaskUseCase(repo);
    registerFallbackValue(validTask);
    registerFallbackValue(const TaskFilter());
  });

  test('returns created task on success', () async {
    when(() => repo.createTask(any())).thenAnswer((_) async => Right(validTask));
    final result = await usecase(validTask);
    expect(result, Right<Failure, Task>(validTask));
  });

  test('returns TaskValidationFailure when title is empty', () async {
    final emptyTitleTask = validTask.copyWith(title: '');
    final result = await usecase(emptyTitleTask);
    result.fold(
      (failure) => expect(failure, isA<TaskValidationFailure>()),
      (_) => fail('Expected failure'),
    );
    verifyNever(() => repo.createTask(any()));
  });
}
