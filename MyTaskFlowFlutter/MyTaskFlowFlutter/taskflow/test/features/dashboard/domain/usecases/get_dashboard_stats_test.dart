import 'package:dartz/dartz.dart' hide Task;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskflow/core/error/failures.dart';
import 'package:taskflow/features/dashboard/domain/entities/task_stats.dart';
import 'package:taskflow/features/dashboard/domain/usecases/get_dashboard_stats_usecase.dart';
import 'package:taskflow/features/tasks/domain/entities/task_entity.dart';
import 'package:taskflow/features/tasks/domain/entities/task_priority.dart';
import 'package:taskflow/features/tasks/domain/repositories/task_repository.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

Task _task({required bool isCompleted}) {
  final now = DateTime.now();
  return Task(
    id: 'id',
    title: 'T',
    description: '',
    dueDate: now.add(const Duration(days: 1)),
    category: 'Work',
    priority: TaskPriority.medium,
    isCompleted: isCompleted,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late MockTaskRepository repo;
  late GetDashboardStatsUseCase useCase;

  setUp(() {
    repo = MockTaskRepository();
    useCase = GetDashboardStatsUseCase(repo);
  });

  test('returns TaskStats calculated from task list', () async {
    final tasks = [_task(isCompleted: true), _task(isCompleted: false)];
    when(() => repo.getAllTasks()).thenAnswer((_) async => Right(tasks));

    final result = await useCase();

    expect(result.isRight(), true);
    result.fold((_) {}, (stats) {
      expect(stats.totalTasks, 2);
      expect(stats.completedTasks, 1);
      expect(stats.pendingTasks, 1);
    });
  });

  test('returns Left(Failure) when repo fails', () async {
    when(() => repo.getAllTasks())
        .thenAnswer((_) async => const Left(StorageFailure('db error')));

    final result = await useCase();

    expect(result.isLeft(), true);
  });

  test('returns correct stats for mixed list with overdue tasks', () async {
    final past = DateTime.now().subtract(const Duration(hours: 1));
    final tasks = [
      Task(
        id: '1',
        title: 'T',
        description: '',
        dueDate: past,
        category: 'W',
        priority: TaskPriority.high,
        isCompleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      _task(isCompleted: true),
    ];
    when(() => repo.getAllTasks()).thenAnswer((_) async => Right(tasks));

    final result = await useCase();

    result.fold((_) {}, (stats) {
      expect(stats, isA<TaskStats>());
      expect(stats.overdueTasks, 1);
      expect(stats.completedTasks, 1);
    });
  });
}
