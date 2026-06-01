import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/features/tasks/domain/entities/task_filter.dart';
import 'package:taskflow/features/tasks/domain/entities/task_priority.dart';
import 'package:taskflow/features/tasks/presentation/widgets/filter_chips.dart';

void main() {
  Widget wrap({
    TaskFilter activeFilter = const TaskFilter(),
    required ValueChanged<TaskFilter> onFilterChanged,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: FilterChips(
          activeFilter: activeFilter,
          onFilterChanged: onFilterChanged,
        ),
      ),
    );
  }

  testWidgets('Muestra chips: Todos, Pendiente, Completado, Alta prioridad, Vencidas',
      (tester) async {
    await tester.pumpWidget(wrap(onFilterChanged: (_) {}));
    expect(find.text('Todos'), findsOneWidget);
    expect(find.text('Pendiente'), findsOneWidget);
    expect(find.text('Completado'), findsOneWidget);
    expect(find.text('Alta prioridad'), findsOneWidget);
    expect(find.text('Vencidas'), findsOneWidget);
  });

  testWidgets('Chip "Todos" está seleccionado por defecto', (tester) async {
    await tester.pumpWidget(wrap(onFilterChanged: (_) {}));
    final chips = tester.widgetList<FilterChip>(find.byType(FilterChip)).toList();
    expect(chips.first.selected, true);
  });

  testWidgets('Tap en chip llama onFilterChanged con el filtro correcto',
      (tester) async {
    TaskFilter? received;
    await tester.pumpWidget(wrap(onFilterChanged: (f) => received = f));
    await tester.tap(find.text('Pendiente'));
    await tester.pump();
    expect(received, const TaskFilter(isCompleted: false));
  });

  testWidgets('Tap en "Alta prioridad" pasa filtro correcto', (tester) async {
    TaskFilter? received;
    await tester.pumpWidget(wrap(onFilterChanged: (f) => received = f));
    await tester.tap(find.text('Alta prioridad'));
    await tester.pump();
    expect(received, const TaskFilter(priority: TaskPriority.high));
  });

  testWidgets('Chip activo muestra estado seleccionado', (tester) async {
    await tester.pumpWidget(
      wrap(
        activeFilter: const TaskFilter(isCompleted: true),
        onFilterChanged: (_) {},
      ),
    );
    final chips = tester.widgetList<FilterChip>(find.byType(FilterChip)).toList();
    final completedChip = chips[2]; // index 2 = 'Completado'
    expect(completedChip.selected, true);
  });
}
