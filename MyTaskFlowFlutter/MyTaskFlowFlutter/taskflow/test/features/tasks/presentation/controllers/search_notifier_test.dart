import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/features/tasks/domain/entities/task_entity.dart';
import 'package:taskflow/features/tasks/domain/entities/task_filter.dart';
import 'package:taskflow/features/tasks/domain/entities/task_priority.dart';
import 'package:taskflow/features/tasks/presentation/controllers/search_notifier.dart';
import 'package:taskflow/features/tasks/presentation/controllers/search_state.dart';

Task _task({
  required String id,
  String title = 'Task',
  String description = '',
  bool isCompleted = false,
  TaskPriority priority = TaskPriority.medium,
  DateTime? dueDate,
}) {
  final now = DateTime.now();
  return Task(
    id: id,
    title: title,
    description: description,
    dueDate: dueDate ?? now.add(const Duration(days: 1)),
    category: 'Work',
    priority: priority,
    isCompleted: isCompleted,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late SearchNotifier notifier;

  setUp(() {
    notifier = SearchNotifier();
  });

  test('initial state has empty filteredTasks', () {
    expect(notifier.state.filteredTasks, isEmpty);
    expect(notifier.state, isA<SearchState>());
  });

  group('updateTasks', () {
    test('estado inicial: todas las tareas visibles', () {
      final tasks = [_task(id: '1'), _task(id: '2')];
      notifier.updateTasks(tasks);
      expect(notifier.state.filteredTasks.length, 2);
    });
  });

  group('updateQuery', () {
    test('filtra por keyword en título', () {
      notifier.updateTasks([
        _task(id: '1', title: 'Flutter development'),
        _task(id: '2', title: 'Meeting with team'),
      ]);
      notifier.updateQuery('flutter');
      expect(notifier.state.filteredTasks.length, 1);
      expect(notifier.state.filteredTasks.first.id, '1');
    });

    test('filtra por keyword en descripción', () {
      notifier.updateTasks([
        _task(id: '1', description: 'Riverpod state management'),
        _task(id: '2', description: 'UI design review'),
      ]);
      notifier.updateQuery('riverpod');
      expect(notifier.state.filteredTasks.length, 1);
    });

    test('filtro sin mayúsculas/minúsculas', () {
      notifier.updateTasks([_task(id: '1', title: 'Flutter Test')]);
      notifier.updateQuery('FLUTTER');
      expect(notifier.state.filteredTasks.length, 1);
    });
  });

  group('updateFilter', () {
    test('filtra tareas pendientes', () {
      notifier.updateTasks([
        _task(id: '1', isCompleted: false),
        _task(id: '2', isCompleted: true),
      ]);
      notifier.updateFilter(const TaskFilter(isCompleted: false));
      expect(notifier.state.filteredTasks.every((t) => !t.isCompleted), true);
    });

    test('filtra tareas completadas', () {
      notifier.updateTasks([
        _task(id: '1', isCompleted: false),
        _task(id: '2', isCompleted: true),
      ]);
      notifier.updateFilter(const TaskFilter(isCompleted: true));
      expect(notifier.state.filteredTasks.every((t) => t.isCompleted), true);
    });

    test('filtra por prioridad alta', () {
      notifier.updateTasks([
        _task(id: '1', priority: TaskPriority.high),
        _task(id: '2', priority: TaskPriority.low),
      ]);
      notifier.updateFilter(const TaskFilter(priority: TaskPriority.high));
      expect(notifier.state.filteredTasks.length, 1);
      expect(notifier.state.filteredTasks.first.id, '1');
    });

    test('filtra tareas vencidas', () {
      final past = DateTime.now().subtract(const Duration(hours: 1));
      notifier.updateTasks([
        _task(id: '1', dueDate: past, isCompleted: false),
        _task(id: '2'),
      ]);
      notifier.updateFilter(const TaskFilter(isOverdue: true));
      expect(notifier.state.filteredTasks.length, 1);
      expect(notifier.state.filteredTasks.first.id, '1');
    });
  });

  test('clearFilters restaura lista completa', () {
    final tasks = [_task(id: '1'), _task(id: '2')];
    notifier.updateTasks(tasks);
    notifier.updateQuery('xyz');
    expect(notifier.state.filteredTasks, isEmpty);
    notifier.clearFilters();
    expect(notifier.state.filteredTasks.length, 2);
  });

  test('combinación de query + filter funciona', () {
    notifier.updateTasks([
      _task(id: '1', title: 'Flutter high', priority: TaskPriority.high),
      _task(id: '2', title: 'Flutter low', priority: TaskPriority.low),
      _task(id: '3', title: 'Meeting high', priority: TaskPriority.high),
    ]);
    notifier.updateQuery('flutter');
    notifier.updateFilter(const TaskFilter(priority: TaskPriority.high));
    expect(notifier.state.filteredTasks.length, 1);
    expect(notifier.state.filteredTasks.first.id, '1');
  });
}
