import 'package:flutter/material.dart';
import 'package:taskflow/features/tasks/domain/entities/task_filter.dart';
import 'package:taskflow/features/tasks/domain/entities/task_priority.dart';

class FilterChips extends StatelessWidget {
  const FilterChips({
    super.key,
    required this.activeFilter,
    required this.onFilterChanged,
  });

  final TaskFilter activeFilter;
  final ValueChanged<TaskFilter> onFilterChanged;

  static const _options = [
    (label: 'Todos', filter: TaskFilter()),
    (label: 'Pendiente', filter: TaskFilter(isCompleted: false)),
    (label: 'Completado', filter: TaskFilter(isCompleted: true)),
    (label: 'Alta prioridad', filter: TaskFilter(priority: TaskPriority.high)),
    (label: 'Vencidas', filter: TaskFilter(isOverdue: true)),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _options.map((opt) {
          final isSelected = activeFilter == opt.filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(opt.label),
              selected: isSelected,
              onSelected: (_) => onFilterChanged(opt.filter),
            ),
          );
        }).toList(),
      ),
    );
  }
}
