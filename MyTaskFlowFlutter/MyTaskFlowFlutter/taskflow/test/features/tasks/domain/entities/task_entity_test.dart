import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/features/tasks/domain/entities/task_entity.dart';
import 'package:taskflow/features/tasks/domain/entities/task_priority.dart';

void main() {
  final fixedDate = DateTime(2026, 6, 1);
  final pastDate = DateTime(2020, 1, 1);

  Task buildTask({
    String id = 'test-id',
    String title = 'Test Task',
    bool isCompleted = false,
    DateTime? dueDate,
  }) {
    return Task(
      id: id,
      title: title,
      description: 'desc',
      dueDate: dueDate ?? fixedDate,
      category: 'Personal',
      priority: TaskPriority.medium,
      isCompleted: isCompleted,
      createdAt: DateTime(2026, 5, 1),
      updatedAt: DateTime(2026, 5, 1),
    );
  }

  group('Task equality', () {
    test('two Tasks with same id are equal', () {
      final a = buildTask(id: 'abc');
      final b = buildTask(id: 'abc', title: 'Different title');
      expect(a, equals(b));
    });

    test('two Tasks with different ids are not equal', () {
      final a = buildTask(id: 'abc');
      final b = buildTask(id: 'xyz');
      expect(a, isNot(equals(b)));
    });
  });

  group('Task.create()', () {
    test('generates non-empty id', () {
      final task = Task.create(
        title: 'New',
        description: '',
        dueDate: fixedDate,
        category: 'Trabajo',
        priority: TaskPriority.high,
      );
      expect(task.id, isNotEmpty);
      expect(task.isCompleted, isFalse);
      expect(task.createdAt, isNotNull);
      expect(task.updatedAt, isNotNull);
    });

    test('two created tasks have different ids', () {
      final a = Task.create(
        title: 'A',
        description: '',
        dueDate: fixedDate,
        category: 'Personal',
        priority: TaskPriority.low,
      );
      final b = Task.create(
        title: 'B',
        description: '',
        dueDate: fixedDate,
        category: 'Personal',
        priority: TaskPriority.low,
      );
      expect(a.id, isNot(equals(b.id)));
    });
  });

  group('copyWith()', () {
    test('modifies only the specified fields', () {
      final original = buildTask(title: 'Original');
      final updated = original.copyWith(title: 'Updated');
      expect(updated.title, 'Updated');
      expect(updated.id, original.id);
      expect(updated.category, original.category);
    });
  });

  group('isOverdue', () {
    test('returns true when dueDate is past and not completed', () {
      final task = buildTask(isCompleted: false, dueDate: pastDate);
      expect(task.isOverdue, isTrue);
    });

    test('returns false when task is completed even if dueDate is past', () {
      final task = buildTask(isCompleted: true, dueDate: pastDate);
      expect(task.isOverdue, isFalse);
    });

    test('returns false when dueDate is future', () {
      final task = buildTask(isCompleted: false, dueDate: fixedDate);
      expect(task.isOverdue, isFalse);
    });
  });

  group('TaskPriority.label', () {
    test('each priority has a readable label', () {
      expect(TaskPriority.low.label, 'Baja');
      expect(TaskPriority.medium.label, 'Media');
      expect(TaskPriority.high.label, 'Alta');
      expect(TaskPriority.urgent.label, 'Urgente');
    });
  });
}
