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
import 'package:taskflow/features/tasks/presentation/pages/task_form_page.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

final _existingTask = Task(
  id: 'edit-id',
  title: 'Título existente',
  description: 'Desc existente',
  dueDate: DateTime(2026, 12, 31),
  category: 'Trabajo',
  priority: TaskPriority.high,
  isCompleted: false,
  createdAt: DateTime(2026, 5, 1),
  updatedAt: DateTime(2026, 5, 1),
);

Widget _wrap(MockTaskRepository repo, {Task? task}) {
  final isEdit = task != null;
  return ProviderScope(
    overrides: [taskRepositoryProvider.overrideWithValue(repo)],
    child: MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: isEdit ? '/tasks/edit-id/edit' : '/tasks/create',
        routes: [
          GoRoute(
            path: '/tasks',
            builder: (context, state) => const Scaffold(body: Text('Lista')),
            routes: [
              GoRoute(
                path: 'create',
                builder: (context, state) => const TaskFormPage(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) => const Scaffold(),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => TaskFormPage(task: task),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

void main() {
  late MockTaskRepository repo;

  setUp(() {
    repo = MockTaskRepository();
    registerFallbackValue(_existingTask);
    registerFallbackValue(const TaskFilter());
  });

  testWidgets('Modo crear: campos vacíos', (tester) async {
    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();
    final titleField = tester.widget<TextFormField>(
      find.byKey(const Key('titleField')),
    );
    expect((titleField.controller?.text ?? ''), isEmpty);
  });

  testWidgets('Modo editar: campos pre-rellenados', (tester) async {
    await tester.pumpWidget(_wrap(repo, task: _existingTask));
    await tester.pumpAndSettle();
    expect(find.text(_existingTask.title), findsOneWidget);
    expect(find.text(_existingTask.description), findsOneWidget);
  });

  testWidgets('Validación: título requerido', (tester) async {
    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('saveButton')));
    await tester.pumpAndSettle();
    expect(find.text('El título es requerido'), findsOneWidget);
  });

  testWidgets('Submit válido llama updateTask en modo editar', (tester) async {
    when(() => repo.updateTask(any()))
        .thenAnswer((_) async => Right(_existingTask));
    when(() => repo.getAllTasks()).thenAnswer((_) async => const Right([]));

    await tester.pumpWidget(_wrap(repo, task: _existingTask));
    await tester.pumpAndSettle();

    // title is pre-filled, date is pre-filled — just tap save
    await tester.tap(find.byKey(const Key('saveButton')));
    await tester.pumpAndSettle();
    verify(() => repo.updateTask(any())).called(1);
  });
}
