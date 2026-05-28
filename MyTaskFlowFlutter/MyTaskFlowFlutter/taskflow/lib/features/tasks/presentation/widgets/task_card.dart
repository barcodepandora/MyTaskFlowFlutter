import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:taskflow/features/tasks/domain/entities/task_entity.dart';
import 'priority_badge.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onTap,
    this.onDelete,
  });

  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    Widget card = Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: Checkbox(
          key: Key('taskCheckbox_${task.id}'),
          value: task.isCompleted,
          onChanged: (_) => onToggle(),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration:
                task.isCompleted ? TextDecoration.lineThrough : null,
            color: task.isCompleted ? Colors.grey : null,
          ),
        ),
        subtitle: Row(
          children: [
            PriorityBadge(priority: task.priority),
            const SizedBox(width: 8),
            Text(
              DateFormat('dd/MM/yy').format(task.dueDate),
              style: TextStyle(
                fontSize: 12,
                color: task.isOverdue ? Colors.red : Colors.grey[600],
              ),
            ),
            if (task.isOverdue) ...[
              const SizedBox(width: 4),
              const Icon(Icons.warning_amber, size: 14, color: Colors.red),
            ],
          ],
        ),
        trailing: onDelete != null
            ? IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: onDelete,
              )
            : null,
      ),
    );

    return card;
  }
}
