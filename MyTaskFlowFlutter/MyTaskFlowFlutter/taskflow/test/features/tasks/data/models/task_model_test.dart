import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/features/tasks/data/models/task_model.dart';
import 'package:taskflow/features/tasks/domain/entities/task_entity.dart';
import 'package:taskflow/features/tasks/domain/entities/task_priority.dart';

void main() {
  final fixedDate = DateTime.utc(2026, 6, 1, 12, 0, 0);
  final createdAt = DateTime.utc(2026, 5, 1);
  final updatedAt = DateTime.utc(2026, 5, 28);

  final taskModel = TaskModel(
    id: 'id-1',
    title: 'Buy milk',
    description: 'Semi-skimmed',
    dueDate: fixedDate,
    category: 'Personal',
    priority: TaskPriority.medium,
    isCompleted: false,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  final taskJson = {
    'id': 'id-1',
    'title': 'Buy milk',
    'description': 'Semi-skimmed',
    'dueDate': fixedDate.toIso8601String(),
    'category': 'Personal',
    'priority': 'medium',
    'isCompleted': false,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  group('TaskModel.fromJson', () {
    test('builds model from JSON correctly', () {
      final model = TaskModel.fromJson(taskJson);
      expect(model.id, taskModel.id);
      expect(model.title, taskModel.title);
      expect(model.description, taskModel.description);
      expect(model.category, taskModel.category);
      expect(model.priority, taskModel.priority);
      expect(model.isCompleted, taskModel.isCompleted);
    });
  });

  group('TaskModel.toJson', () {
    test('serializes to JSON (roundtrip)', () {
      final json = taskModel.toJson();
      final restored = TaskModel.fromJson(json);
      expect(restored.id, taskModel.id);
      expect(restored.title, taskModel.title);
      expect(restored.priority, taskModel.priority);
    });
  });

  group('TaskModel.toEntity', () {
    test('returns Task with same values', () {
      final entity = taskModel.toEntity();
      expect(entity, isA<Task>());
      expect(entity.id, taskModel.id);
      expect(entity.priority, taskModel.priority);
    });
  });

  group('TaskModel.fromEntity', () {
    test('builds TaskModel from Task', () {
      final entity = Task(
        id: 'id-2',
        title: 'Walk dog',
        description: '',
        dueDate: fixedDate,
        category: 'Personal',
        priority: TaskPriority.low,
        isCompleted: false,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
      final model = TaskModel.fromEntity(entity);
      expect(model.id, entity.id);
      expect(model.title, entity.title);
      expect(model.priority, entity.priority);
    });
  });
}
