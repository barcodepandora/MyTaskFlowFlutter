import 'package:dartz/dartz.dart' hide Task;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskflow/features/tasks/data/providers/tasks_providers.dart';
import 'package:taskflow/features/tasks/domain/entities/task_entity.dart';
import 'package:taskflow/features/tasks/domain/entities/task_filter.dart';
import 'package:taskflow/features/tasks/domain/entities/task_priority.dart';
import 'package:taskflow/features/tasks/domain/repositories/task_repository.dart';
import 'package:taskflow/features/tasks/presentation/pages/task_list_page.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

Task _task(String id, String title) => Task(
      id: id,
      title: title,
      description: '',
      dueDate: DateTime(2030, 1, 1),
      category: 'Personal',
      priority: TaskPriority.medium,
      isCompleted: false,
      createdAt: DateTime(2026, 5, 1),
      updatedAt: DateTime(2026, 5, 1),
    );

Widget _wrap(MockTaskRepository repo) {
  return ProviderScope(
    overrides: [
      taskRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const TaskListPage(),
          ),
          GoRoute(path: '/tasks/create', builder: (context, state) => const SizedBox()),
          GoRoute(
              path: '/tasks/:id',
              builder: (context, state) => const SizedBox()),
        ],
      ),
    ),
  );
}

void main() {
  late MockTaskRepository repo;

  setUp(() {
    repo = MockTaskRepository();
    registerFallbackValue(const TaskFilter());
  });

  testWidgets('Muestra CircularProgressIndicator cuando carga', (tester) async {
    // Use a Completer so the future never resolves during this test
    when(() => repo.getAllTasks()).thenAnswer(
      (_) async {
        await Future.delayed(const Duration(milliseconds: 500));
        return const Right([]);
      },
    );
    await tester.pumpWidget(_wrap(repo));
    // After first microtask (loadTasks starts) but before future resolves
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('Muestra EmptyState cuando no hay tareas', (tester) async {
    when(() => repo.getAllTasks()).thenAnswer((_) async => const Right([]));
    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();
    expect(find.text('No tienes tareas aún'), findsOneWidget);
  });

  testWidgets('Muestra lista de TaskCards cuando hay tareas', (tester) async {
    final tasks = [_task('1', 'Tarea A'), _task('2', 'Tarea B')];
    when(() => repo.getAllTasks()).thenAnswer((_) async => Right(tasks));
    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();
    expect(find.text('Tarea A'), findsOneWidget);
    expect(find.text('Tarea B'), findsOneWidget);
  });

  testWidgets('FAB está presente', (tester) async {
    when(() => repo.getAllTasks()).thenAnswer((_) async => const Right([]));
    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('addTaskFAB')), findsOneWidget);
  });
}
