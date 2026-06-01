import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/features/tasks/domain/entities/task_entity.dart';
import 'package:taskflow/features/tasks/domain/entities/task_priority.dart';
import 'package:taskflow/features/tasks/presentation/widgets/task_card.dart';

void main() {
  Task buildTask({
    String id = 'task-1',
    String title = 'Test task',
    bool isCompleted = false,
    DateTime? dueDate,
  }) {
    return Task(
      id: id,
      title: title,
      description: '',
      dueDate: dueDate ?? DateTime(2030, 1, 1),
      category: 'Personal',
      priority: TaskPriority.medium,
      isCompleted: isCompleted,
      createdAt: DateTime(2026, 5, 1),
      updatedAt: DateTime(2026, 5, 1),
    );
  }

  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('TaskCard muestra título y prioridad', (tester) async {
    final task = buildTask(title: 'Comprar leche');
    await tester.pumpWidget(wrap(TaskCard(
      task: task,
      onToggle: () {},
      onTap: () {},
    )));
    expect(find.text('Comprar leche'), findsOneWidget);
    expect(find.text('Media'), findsOneWidget);
  });

  testWidgets('Tap en checkbox llama onToggle', (tester) async {
    final task = buildTask();
    var toggled = false;
    await tester.pumpWidget(wrap(TaskCard(
      task: task,
      onToggle: () => toggled = true,
      onTap: () {},
    )));
    await tester.tap(find.byKey(Key('taskCheckbox_${task.id}')));
    expect(toggled, isTrue);
  });

  testWidgets('Tarea completada muestra título con tachado', (tester) async {
    final task = buildTask(isCompleted: true);
    await tester.pumpWidget(wrap(TaskCard(
      task: task,
      onToggle: () {},
      onTap: () {},
    )));
    final textWidget = tester.widget<Text>(find.text(task.title));
    expect(textWidget.style?.decoration, TextDecoration.lineThrough);
  });

  testWidgets('Tarea vencida muestra indicador rojo', (tester) async {
    final task = buildTask(dueDate: DateTime(2020, 1, 1), isCompleted: false);
    await tester.pumpWidget(wrap(TaskCard(
      task: task,
      onToggle: () {},
      onTap: () {},
    )));
    expect(find.byIcon(Icons.warning_amber), findsOneWidget);
  });
}
