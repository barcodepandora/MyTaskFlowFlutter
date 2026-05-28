import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taskflow/features/tasks/data/providers/tasks_providers.dart';
import 'package:taskflow/features/tasks/presentation/controllers/tasks_state.dart';
import 'package:taskflow/features/tasks/presentation/widgets/empty_state_widget.dart';
import 'package:taskflow/features/tasks/presentation/widgets/task_card.dart';

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
    final state = ref.watch(tasksNotifierProvider);

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
      body: switch (state) {
        TasksLoading() => const Center(child: CircularProgressIndicator()),
        TasksLoaded(tasks: final tasks) when tasks.isEmpty =>
          const EmptyStateWidget(message: 'No tienes tareas aún'),
        TasksLoaded(tasks: final tasks) => ListView.builder(
            key: const Key('taskList'),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return TaskCard(
                task: task,
                onToggle: () => ref
                    .read(tasksNotifierProvider.notifier)
                    .toggleComplete(task),
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
      },
      floatingActionButton: FloatingActionButton(
        key: const Key('addTaskFAB'),
        onPressed: () => context.push('/tasks/create'),
        child: const Icon(Icons.add),
      ),
    );
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
