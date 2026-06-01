import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:taskflow/features/tasks/domain/entities/task_entity.dart';

class RecentActivityList extends StatelessWidget {
  const RecentActivityList({super.key, required this.tasks, this.onTap});

  final List<Task> tasks;
  final void Function(Task)? onTap;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: Text('Sin actividad reciente')),
      );
    }
    return Column(
      children: tasks.map((task) => _ActivityTile(task: task, onTap: onTap)).toList(),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.task, this.onTap});

  final Task task;
  final void Function(Task)? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(
        task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
        color: task.isCompleted ? Colors.green : Colors.grey,
      ),
      title: Text(
        task.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Text(DateFormat.yMMMd().format(task.updatedAt)),
      onTap: onTap != null ? () => onTap!(task) : null,
    );
  }
}
