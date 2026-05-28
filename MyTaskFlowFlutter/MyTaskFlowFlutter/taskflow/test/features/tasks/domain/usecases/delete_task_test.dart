import 'package:dartz/dartz.dart' hide Task;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskflow/core/error/failures.dart';
import 'package:taskflow/features/tasks/domain/entities/task_filter.dart';
import 'package:taskflow/features/tasks/domain/repositories/task_repository.dart';
import 'package:taskflow/features/tasks/domain/usecases/delete_task_usecase.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  late MockTaskRepository repo;
  late DeleteTaskUseCase usecase;

  setUp(() {
    repo = MockTaskRepository();
    usecase = DeleteTaskUseCase(repo);
    registerFallbackValue(const TaskFilter());
  });

  test('returns void on success', () async {
    when(() => repo.deleteTask(any())).thenAnswer((_) async => const Right(null));
    final result = await usecase('id-1');
    expect(result, const Right<Failure, void>(null));
  });

  test('propagates TaskNotFoundFailure', () async {
    when(() => repo.deleteTask(any()))
        .thenAnswer((_) async => const Left(TaskNotFoundFailure()));
    final result = await usecase('id-missing');
    expect(result, const Left<Failure, void>(TaskNotFoundFailure()));
  });
}
