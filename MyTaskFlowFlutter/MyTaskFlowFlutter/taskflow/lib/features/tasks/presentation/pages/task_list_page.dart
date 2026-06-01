import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taskflow/features/tasks/data/providers/tasks_providers.dart';
import 'package:taskflow/features/tasks/presentation/controllers/search_state.dart';
import 'package:taskflow/features/tasks/presentation/controllers/tasks_state.dart';
import 'package:taskflow/features/tasks/presentation/widgets/empty_state_widget.dart';
import 'package:taskflow/features/tasks/presentation/widgets/filter_chips.dart';
import 'package:taskflow/features/tasks/presentation/widgets/task_card.dart';
import 'package:taskflow/features/tasks/presentation/widgets/task_search_bar.dart';

class TaskListPage extends ConsumerStatefulWidget {
  const TaskListPage({super.key});

  @override
  ConsumerState<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends ConsumerState<TaskListPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(tasksNotifierProvider.notifier).loadTasks(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasksState = ref.watch(tasksNotifierProvider);
    final searchState = ref.watch(searchNotifierProvider);

    ref.listen<TasksState>(tasksNotifierProvider, (_, next) {
      if (next is TaskOperationSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.message)),
        );
      } else if (next is TasksError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Mis Tareas')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: TaskSearchBar(
              onChanged: (q) =>
                  ref.read(searchNotifierProvider.notifier).updateQuery(q),
              onClear: () =>
                  ref.read(searchNotifierProvider.notifier).clearFilters(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: FilterChips(
              activeFilter: searchState.filter,
              onFilterChanged: (f) =>
                  ref.read(searchNotifierProvider.notifier).updateFilter(f),
            ),
          ),
          Expanded(child: _body(context, tasksState, searchState)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('addTaskFAB'),
        onPressed: () => context.push('/tasks/create'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _body(
      BuildContext context, TasksState tasksState, SearchState searchState) {
    return switch (tasksState) {
      TasksLoading() => const Center(child: CircularProgressIndicator()),
      TasksLoaded(tasks: final tasks) when tasks.isEmpty =>
        const EmptyStateWidget(message: 'No tienes tareas aún'),
      TasksLoaded() when searchState.filteredTasks.isEmpty =>
        const EmptyStateWidget(message: 'Sin resultados'),
      TasksLoaded() => ListView.builder(
          key: const Key('taskList'),
          itemCount: searchState.filteredTasks.length,
          itemBuilder: (context, index) {
            final task = searchState.filteredTasks[index];
            return TaskCard(
              task: task,
              onToggle: () =>
                  ref.read(tasksNotifierProvider.notifier).toggleComplete(task),
              onTap: () => context.push('/tasks/${task.id}', extra: task),
              onDelete: () => _confirmDelete(context, task.id),
            );
          },
        ),
      TasksError(message: final msg) => EmptyStateWidget(
          message: msg,
          icon: Icons.error_outline,
        ),
      _ => const EmptyStateWidget(),
    };
  }

  Future<void> _confirmDelete(BuildContext context, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar tarea'),
        content: const Text('¿Seguro que deseas eliminar esta tarea?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(tasksNotifierProvider.notifier).deleteTask(id);
    }
  }
}
