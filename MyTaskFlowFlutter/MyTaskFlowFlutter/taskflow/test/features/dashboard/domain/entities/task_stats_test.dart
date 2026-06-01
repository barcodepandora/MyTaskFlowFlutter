import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/features/dashboard/domain/entities/task_stats.dart';
import 'package:taskflow/features/tasks/domain/entities/task_entity.dart';
import 'package:taskflow/features/tasks/domain/entities/task_priority.dart';

Task _task({required bool isCompleted, DateTime? dueDate}) {
  final now = DateTime.now();
  return Task(
    id: 'id',
    title: 'Title',
    description: '',
    dueDate: dueDate ?? now.add(const Duration(days: 1)),
    category: 'Work',
    priority: TaskPriority.medium,
    isCompleted: isCompleted,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('TaskStats.fromList', () {
    test('totalTasks equals completedTasks + pendingTasks', () {
      final tasks = [
        _task(isCompleted: true),
        _task(isCompleted: false),
        _task(isCompleted: false),
      ];
      final stats = TaskStats.fromList(tasks);
      expect(stats.totalTasks, stats.completedTasks + stats.pendingTasks);
    });

    test('completionRate returns 0.0 when totalTasks is 0', () {
      final stats = TaskStats.fromList([]);
      expect(stats.completionRate, 0.0);
    });

    test('completionRate returns 1.0 when all tasks are completed', () {
      final tasks = [
        _task(isCompleted: true),
        _task(isCompleted: true),
      ];
      final stats = TaskStats.fromList(tasks);
      expect(stats.completionRate, 1.0);
    });

    test('overdueTasks counts tasks past due and not completed', () {
      final past = DateTime.now().subtract(const Duration(hours: 1));
      final tasks = [
        _task(isCompleted: false, dueDate: past),
        _task(isCompleted: true, dueDate: past),
        _task(isCompleted: false),
      ];
      final stats = TaskStats.fromList(tasks);
      expect(stats.overdueTasks, 1);
    });

    test('calculates correctly with mixed list', () {
      final past = DateTime.now().subtract(const Duration(hours: 1));
      final tasks = [
        _task(isCompleted: true),
        _task(isCompleted: false),
        _task(isCompleted: false, dueDate: past),
      ];
      final stats = TaskStats.fromList(tasks);
      expect(stats.totalTasks, 3);
      expect(stats.completedTasks, 1);
      expect(stats.pendingTasks, 2);
      expect(stats.overdueTasks, 1);
    });

    test('Equatable: two stats with same values are equal', () {
      const a = TaskStats(
        totalTasks: 3,
        completedTasks: 1,
        pendingTasks: 2,
        overdueTasks: 0,
      );
      const b = TaskStats(
        totalTasks: 3,
        completedTasks: 1,
        pendingTasks: 2,
        overdueTasks: 0,
      );
      expect(a, b);
    });
  });
}
