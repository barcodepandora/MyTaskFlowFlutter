import 'package:dartz/dartz.dart' hide Task;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskflow/core/error/failures.dart';
import 'package:taskflow/features/tasks/domain/entities/task_entity.dart';
import 'package:taskflow/features/tasks/domain/entities/task_priority.dart';
import 'package:taskflow/features/tasks/domain/usecases/create_task_usecase.dart';
import 'package:taskflow/features/tasks/domain/usecases/delete_task_usecase.dart';
import 'package:taskflow/features/tasks/domain/usecases/get_all_tasks_usecase.dart';
import 'package:taskflow/features/tasks/domain/usecases/update_task_usecase.dart';
import 'package:taskflow/features/tasks/presentation/controllers/tasks_notifier.dart';
import 'package:taskflow/features/tasks/presentation/controllers/tasks_state.dart';

class MockGetAllTasksUseCase extends Mock implements GetAllTasksUseCase {}

class MockCreateTaskUseCase extends Mock implements CreateTaskUseCase {}

class MockUpdateTaskUseCase extends Mock implements UpdateTaskUseCase {}

class MockDeleteTaskUseCase extends Mock implements DeleteTaskUseCase {}

void main() {
  late MockGetAllTasksUseCase getAllTasks;
  late MockCreateTaskUseCase createTask;
  late MockUpdateTaskUseCase updateTask;
  late MockDeleteTaskUseCase deleteTask;
  late TasksNotifier notifier;

  final sampleTask = Task(
    id: 'task-1',
    title: 'Sample',
    description: '',
    dueDate: DateTime(2026, 12, 31),
    category: 'Personal',
    priority: TaskPriority.medium,
    isCompleted: false,
    createdAt: DateTime(2026, 5, 1),
    updatedAt: DateTime(2026, 5, 1),
  );

  setUp(() {
    getAllTasks = MockGetAllTasksUseCase();
    createTask = MockCreateTaskUseCase();
    updateTask = MockUpdateTaskUseCase();
    deleteTask = MockDeleteTaskUseCase();
    notifier = TasksNotifier(
      getAllTasks: getAllTasks,
      createTask: createTask,
      updateTask: updateTask,
      deleteTask: deleteTask,
    );
    registerFallbackValue(sampleTask);
  });

  test('initial state is TasksInitial', () {
    expect(notifier.state, isA<TasksInitial>());
  });

  group('loadTasks', () {
    test('emits TasksLoaded on success', () async {
      when(() => getAllTasks()).thenAnswer((_) async => Right([sampleTask]));
      await notifier.loadTasks();
      expect(notifier.state, isA<TasksLoaded>());
      expect((notifier.state as TasksLoaded).tasks, [sampleTask]);
    });

    test('emits TasksError on failure', () async {
      when(() => getAllTasks())
          .thenAnswer((_) async => const Left(StorageFailure('db error')));
      await notifier.loadTasks();
      expect(notifier.state, isA<TasksError>());
      expect((notifier.state as TasksError).message, 'db error');
    });
  });

  group('createTask', () {
    test('emits TaskOperationSuccess then reloads on success', () async {
      when(() => createTask(any())).thenAnswer((_) async => Right(sampleTask));
      when(() => getAllTasks()).thenAnswer((_) async => Right([sampleTask]));
      await notifier.createTask(sampleTask);
      expect(notifier.state, isA<TasksLoaded>());
    });

    test('emits TasksError on failure', () async {
      when(() => createTask(any()))
          .thenAnswer((_) async => const Left(TaskValidationFailure()));
      await notifier.createTask(sampleTask);
      expect(notifier.state, isA<TasksError>());
    });
  });

  group('deleteTask', () {
    test('emits TaskOperationSuccess then reloads on success', () async {
      when(() => deleteTask(any())).thenAnswer((_) async => const Right(null));
      when(() => getAllTasks()).thenAnswer((_) async => const Right([]));
      await notifier.deleteTask('task-1');
      expect(notifier.state, isA<TasksLoaded>());
    });
  });

  group('toggleComplete', () {
    test('calls updateTask with inverted isCompleted', () async {
      when(() => updateTask(any())).thenAnswer((_) async => Right(sampleTask));
      when(() => getAllTasks()).thenAnswer((_) async => Right([sampleTask]));
      await notifier.toggleComplete(sampleTask);
      final captured = verify(() => updateTask(captureAny())).captured.first as Task;
      expect(captured.isCompleted, !sampleTask.isCompleted);
    });
  });
}
