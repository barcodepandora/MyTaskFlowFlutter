import 'package:equatable/equatable.dart';

import 'task_priority.dart';

class TaskFilter extends Equatable {
  const TaskFilter({
    this.keyword,
    this.category,
    this.priority,
    this.isCompleted,
    this.isOverdue,
  });

  final String? keyword;
  final String? category;
  final TaskPriority? priority;
  final bool? isCompleted;
  final bool? isOverdue;

  @override
  List<Object?> get props => [keyword, category, priority, isCompleted, isOverdue];
}
