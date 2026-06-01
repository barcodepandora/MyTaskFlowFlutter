import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskflow/core/utils/failure_mapper.dart';
import 'package:taskflow/features/tasks/domain/entities/task_entity.dart';
import 'package:taskflow/features/tasks/domain/usecases/create_task_usecase.dart';
import 'package:taskflow/features/tasks/domain/usecases/delete_task_usecase.dart';
import 'package:taskflow/features/tasks/domain/usecases/get_all_tasks_usecase.dart';
import 'package:taskflow/features/tasks/domain/usecases/update_task_usecase.dart';
import 'tasks_state.dart';

class TasksNotifier extends StateNotifier<TasksState> {
  TasksNotifier({
    required GetAllTasksUseCase getAllTasks,
    required CreateTaskUseCase createTask,
    required UpdateTaskUseCase updateTask,
    required DeleteTaskUseCase deleteTask,
  })  : _getAllTasks = getAllTasks,
        _createTask = createTask,
        _updateTask = updateTask,
        _deleteTask = deleteTask,
        super(const TasksInitial());

  final GetAllTasksUseCase _getAllTasks;
  final CreateTaskUseCase _createTask;
  final UpdateTaskUseCase _updateTask;
  final DeleteTaskUseCase _deleteTask;

  Future<void> loadTasks() async {
    state = const TasksLoading();
    final result = await _getAllTasks();
    state = result.fold(
      (failure) => TasksError(mapFailureToMessage(failure)),
      (tasks) => TasksLoaded(tasks),
    );
  }

  Future<void> createTask(Task task) async {
    state = const TasksLoading();
    final result = await _createTask(task);
    if (result.isLeft()) {
      state = TasksError(
          result.fold((f) => mapFailureToMessage(f), (_) => ''));
      return;
    }
    state = const TaskOperationSuccess('Tarea creada');
    await loadTasks();
  }

  Future<void> updateTask(Task task) async {
    state = const TasksLoading();
    final result = await _updateTask(task);
    if (result.isLeft()) {
      state = TasksError(
          result.fold((f) => mapFailureToMessage(f), (_) => ''));
      return;
    }
    state = const TaskOperationSuccess('Tarea actualizada');
    await loadTasks();
  }

  Future<void> deleteTask(String id) async {
    state = const TasksLoading();
    final result = await _deleteTask(id);
    if (result.isLeft()) {
      state = TasksError(
          result.fold((f) => mapFailureToMessage(f), (_) => ''));
      return;
    }
    state = const TaskOperationSuccess('Tarea eliminada');
    await loadTasks();
  }

  Future<void> toggleComplete(Task task) async {
    final toggled = task.copyWith(
      isCompleted: !task.isCompleted,
      updatedAt: DateTime.now(),
    );
    await updateTask(toggled);
  }
}
