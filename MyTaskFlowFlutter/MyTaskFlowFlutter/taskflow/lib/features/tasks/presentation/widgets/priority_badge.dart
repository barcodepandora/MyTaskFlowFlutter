import 'package:flutter/material.dart';
import 'package:taskflow/features/tasks/domain/entities/task_priority.dart';

class PriorityBadge extends StatelessWidget {
  const PriorityBadge({super.key, required this.priority});

  final TaskPriority priority;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: priority.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: priority.color, width: 1),
      ),
      child: Text(
        priority.label,
        style: TextStyle(
          fontSize: 11,
          color: priority.color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
