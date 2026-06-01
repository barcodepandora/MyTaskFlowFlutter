import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taskflow/features/tasks/data/datasources/in_memory_task_datasource.dart';
import 'package:taskflow/features/tasks/domain/repositories/task_repository.dart';
import 'package:taskflow/features/tasks/domain/usecases/create_task_usecase.dart';
import 'package:taskflow/features/tasks/domain/usecases/delete_task_usecase.dart';
import 'package:taskflow/features/tasks/domain/usecases/get_all_tasks_usecase.dart';
import 'package:taskflow/features/tasks/domain/usecases/search_tasks_usecase.dart';
import 'package:taskflow/features/tasks/domain/usecases/update_task_usecase.dart';
import 'package:taskflow/features/tasks/presentation/controllers/search_notifier.dart';
import 'package:taskflow/features/tasks/presentation/controllers/search_state.dart';
import 'package:taskflow/features/tasks/presentation/controllers/tasks_notifier.dart';
import 'package:taskflow/features/tasks/presentation/controllers/tasks_state.dart';

final taskRepositoryProvider = Provider<TaskRepository>(
  (_) => InMemoryTaskDatasource(),
);

final getAllTasksUseCaseProvider = Provider<GetAllTasksUseCase>(
  (ref) => GetAllTasksUseCase(ref.watch(taskRepositoryProvider)),
);

final createTaskUseCaseProvider = Provider<CreateTaskUseCase>(
  (ref) => CreateTaskUseCase(ref.watch(taskRepositoryProvider)),
);

final updateTaskUseCaseProvider = Provider<UpdateTaskUseCase>(
  (ref) => UpdateTaskUseCase(ref.watch(taskRepositoryProvider)),
);

final deleteTaskUseCaseProvider = Provider<DeleteTaskUseCase>(
  (ref) => DeleteTaskUseCase(ref.watch(taskRepositoryProvider)),
);

final searchTasksUseCaseProvider = Provider<SearchTasksUseCase>(
  (ref) => SearchTasksUseCase(ref.watch(taskRepositoryProvider)),
);

final tasksNotifierProvider =
    StateNotifierProvider<TasksNotifier, TasksState>(
  (ref) => TasksNotifier(
    getAllTasks: ref.watch(getAllTasksUseCaseProvider),
    createTask: ref.watch(createTaskUseCaseProvider),
    updateTask: ref.watch(updateTaskUseCaseProvider),
    deleteTask: ref.watch(deleteTaskUseCaseProvider),
  ),
);

final searchNotifierProvider =
    StateNotifierProvider<SearchNotifier, SearchState>(
  (ref) {
    final notifier = SearchNotifier();
    ref.listen<TasksState>(tasksNotifierProvider, (_, next) {
      if (next is TasksLoaded) notifier.updateTasks(next.tasks);
    }, fireImmediately: true);
    return notifier;
  },
);
