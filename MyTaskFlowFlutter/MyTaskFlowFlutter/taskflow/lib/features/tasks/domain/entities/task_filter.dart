import 'task_priority.dart';

class TaskFilter {
  const TaskFilter({
    this.keyword,
    this.category,
    this.priority,
    this.isCompleted,
  });

  final String? keyword;
  final String? category;
  final TaskPriority? priority;
  final bool? isCompleted;
}
