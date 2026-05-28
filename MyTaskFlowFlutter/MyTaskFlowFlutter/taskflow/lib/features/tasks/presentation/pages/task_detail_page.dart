import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:taskflow/features/tasks/data/providers/tasks_providers.dart';
import 'package:taskflow/features/tasks/domain/entities/task_entity.dart';
import 'package:taskflow/features/tasks/presentation/widgets/priority_badge.dart';

class TaskDetailPage extends ConsumerWidget {
  const TaskDetailPage({super.key, required this.task});

  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(tasksNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('/tasks/${task.id}/edit', extra: task),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                  ),
                ),
                PriorityBadge(priority: task.priority),
              ],
            ),
            const SizedBox(height: 8),
            _infoRow(Icons.folder_outlined, task.category),
            _infoRow(
              Icons.calendar_today,
              DateFormat('dd/MM/yyyy').format(task.dueDate),
              color: task.isOverdue ? Colors.red : null,
            ),
            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Descripción',
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              Text(task.description),
            ],
            const SizedBox(height: 24),
            SwitchListTile(
              title: Text(
                  task.isCompleted ? 'Completada' : 'Marcar como completada'),
              value: task.isCompleted,
              onChanged: (_) => notifier.toggleComplete(task),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color ?? Colors.grey[600]),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: color)),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
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
      ref.read(tasksNotifierProvider.notifier).deleteTask(task.id);
      if (context.mounted) context.pop();
    }
  }
}
