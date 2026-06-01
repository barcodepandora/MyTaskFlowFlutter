import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/features/tasks/data/datasources/in_memory_task_datasource.dart';
import 'package:taskflow/features/tasks/domain/entities/task_entity.dart';
import 'package:taskflow/features/tasks/domain/entities/task_filter.dart';
import 'package:taskflow/features/tasks/domain/entities/task_priority.dart';

void main() {
  late InMemoryTaskDatasource datasource;

  Task buildTask({
    String id = 'new-id',
    String title = 'Test task',
    String category = 'Personal',
    TaskPriority priority = TaskPriority.medium,
    bool isCompleted = false,
  }) {
    final now = DateTime.now();
    return Task(
      id: id,
      title: title,
      description: '',
      dueDate: now.add(const Duration(days: 1)),
      category: category,
      priority: priority,
      isCompleted: isCompleted,
      createdAt: now,
      updatedAt: now,
    );
  }

  setUp(() {
    datasource = InMemoryTaskDatasource();
  });

  group('getAllTasks', () {
    test('returns seed tasks on init', () async {
      final result = await datasource.getAllTasks();
      result.fold(
        (f) => fail('Expected success'),
        (tasks) => expect(tasks.length, 6),
      );
    });
  });

  group('createTask', () {
    test('adds task and returns it', () async {
      final task = buildTask(id: 'new-1');
      final result = await datasource.createTask(task);
      result.fold(
        (f) => fail('Expected success'),
        (t) => expect(t.id, 'new-1'),
      );
      final all = await datasource.getAllTasks();
      all.fold(
        (f) => fail('Expected success'),
        (tasks) => expect(tasks.any((t) => t.id == 'new-1'), isTrue),
      );
    });
  });

  group('getTaskById', () {
    test('returns task when found', () async {
      final result = await datasource.getTaskById('seed-1');
      result.fold(
        (f) => fail('Expected success'),
        (t) => expect(t.id, 'seed-1'),
      );
    });

    test('returns TaskNotFoundFailure when not found', () async {
      final result = await datasource.getTaskById('unknown');
      expect(result.isLeft(), isTrue);
    });
  });

  group('updateTask', () {
    test('replaces existing task', () async {
      final updated = buildTask(id: 'seed-1', title: 'Updated title', category: 'Trabajo');
      final result = await datasource.updateTask(updated);
      result.fold(
        (f) => fail('Expected success'),
        (t) => expect(t.title, 'Updated title'),
      );
    });

    test('returns TaskNotFoundFailure if id not found', () async {
      final result = await datasource.updateTask(buildTask(id: 'ghost'));
      expect(result.isLeft(), isTrue);
    });
  });

  group('deleteTask', () {
    test('removes task by id', () async {
      await datasource.deleteTask('seed-1');
      final all = await datasource.getAllTasks();
      all.fold(
        (f) => fail('Expected success'),
        (tasks) => expect(tasks.any((t) => t.id == 'seed-1'), isFalse),
      );
    });

    test('returns TaskNotFoundFailure if not found', () async {
      final result = await datasource.deleteTask('ghost');
      expect(result.isLeft(), isTrue);
    });
  });

  group('searchTasks', () {
    test('filters by keyword in title', () async {
      final result = await datasource.searchTasks(const TaskFilter(keyword: 'correos'));
      result.fold(
        (f) => fail('Expected success'),
        (tasks) {
          expect(tasks.isNotEmpty, isTrue);
          expect(tasks.every((t) => t.title.contains('correos')), isTrue);
        },
      );
    });

    test('filters by category', () async {
      final result = await datasource.searchTasks(const TaskFilter(category: 'Salud'));
      result.fold(
        (f) => fail('Expected success'),
        (tasks) => expect(tasks.every((t) => t.category == 'Salud'), isTrue),
      );
    });

    test('filters by isCompleted', () async {
      final result = await datasource.searchTasks(const TaskFilter(isCompleted: true));
      result.fold(
        (f) => fail('Expected success'),
        (tasks) => expect(tasks.every((t) => t.isCompleted), isTrue),
      );
    });

    test('filters by priority', () async {
      final result = await datasource.searchTasks(const TaskFilter(priority: TaskPriority.high));
      result.fold(
        (f) => fail('Expected success'),
        (tasks) => expect(tasks.every((t) => t.priority == TaskPriority.high), isTrue),
      );
    });
  });
}
