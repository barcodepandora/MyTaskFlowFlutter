import 'package:taskflow/features/tasks/domain/entities/task_entity.dart';

sealed class TasksState {
  const TasksState();
}

class TasksInitial extends TasksState {
  const TasksInitial();
}

class TasksLoading extends TasksState {
  const TasksLoading();
}

class TasksLoaded extends TasksState {
  const TasksLoaded(this.tasks);
  final List<Task> tasks;
}

class TasksError extends TasksState {
  const TasksError(this.message);
  final String message;
}

class TaskOperationSuccess extends TasksState {
  const TaskOperationSuccess(this.message);
  final String message;
}
