import 'package:dartz/dartz.dart' hide Task;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskflow/core/error/failures.dart';
import 'package:taskflow/features/dashboard/domain/usecases/get_recent_activity_usecase.dart';
import 'package:taskflow/features/tasks/domain/entities/task_entity.dart';
import 'package:taskflow/features/tasks/domain/entities/task_priority.dart';
import 'package:taskflow/features/tasks/domain/repositories/task_repository.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

Task _task(String id, DateTime updatedAt) => Task(
      id: id,
      title: 'Task $id',
      description: '',
      dueDate: DateTime.now().add(const Duration(days: 1)),
      category: 'Work',
      priority: TaskPriority.medium,
      isCompleted: false,
      createdAt: DateTime.now(),
      updatedAt: updatedAt,
    );

void main() {
  late MockTaskRepository repo;
  late GetRecentActivityUseCase useCase;

  setUp(() {
    repo = MockTaskRepository();
    useCase = GetRecentActivityUseCase(repo);
  });

  test('returns tasks ordered by updatedAt DESC', () async {
    final older = DateTime(2026, 1, 1);
    final newer = DateTime(2026, 6, 1);
    final tasks = [_task('a', older), _task('b', newer)];
    when(() => repo.getAllTasks()).thenAnswer((_) async => Right(tasks));

    final result = await useCase();

    result.fold((_) {}, (list) {
      expect(list.first.id, 'b');
      expect(list.last.id, 'a');
    });
  });

  test('limits result to maxItems', () async {
    final tasks = List.generate(
      10,
      (i) => _task('$i', DateTime(2026, 1, i + 1)),
    );
    when(() => repo.getAllTasks()).thenAnswer((_) async => Right(tasks));

    final result = await useCase(maxItems: 5);

    result.fold((_) {}, (list) => expect(list.length, 5));
  });

  test('returns Left(Failure) when repo fails', () async {
    when(() => repo.getAllTasks())
        .thenAnswer((_) async => const Left(StorageFailure()));

    final result = await useCase();

    expect(result.isLeft(), true);
  });
}
