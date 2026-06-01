import 'package:equatable/equatable.dart';
import 'package:taskflow/features/tasks/domain/entities/task_entity.dart';

class TaskStats extends Equatable {
  const TaskStats({
    required this.totalTasks,
    required this.completedTasks,
    required this.pendingTasks,
    required this.overdueTasks,
  });

  factory TaskStats.fromList(List<Task> tasks) {
    final completed = tasks.where((t) => t.isCompleted).length;
    final pending = tasks.where((t) => !t.isCompleted).length;
    final overdue = tasks.where((t) => t.isOverdue).length;
    return TaskStats(
      totalTasks: tasks.length,
      completedTasks: completed,
      pendingTasks: pending,
      overdueTasks: overdue,
    );
  }

  final int totalTasks;
  final int completedTasks;
  final int pendingTasks;
  final int overdueTasks;

  double get completionRate =>
      totalTasks == 0 ? 0.0 : completedTasks / totalTasks;

  @override
  List<Object?> get props => [totalTasks, completedTasks, pendingTasks, overdueTasks];
}
