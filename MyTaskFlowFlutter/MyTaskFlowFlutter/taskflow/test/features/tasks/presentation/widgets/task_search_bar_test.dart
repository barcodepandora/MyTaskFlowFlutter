import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/features/tasks/presentation/widgets/task_search_bar.dart';

void main() {
  Widget wrap({
    required ValueChanged<String> onChanged,
    required VoidCallback onClear,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: TaskSearchBar(onChanged: onChanged, onClear: onClear),
      ),
    );
  }

  testWidgets('Muestra campo de texto con hint "Buscar tareas..."',
      (tester) async {
    await tester.pumpWidget(wrap(onChanged: (_) {}, onClear: () {}));
    expect(find.text('Buscar tareas...'), findsOneWidget);
  });

  testWidgets('onChanged se llama después del debounce', (tester) async {
    String? captured;
    await tester.pumpWidget(
      wrap(onChanged: (v) => captured = v, onClear: () {}),
    );
    await tester.enterText(find.byKey(const Key('taskSearchField')), 'flutter');
    await tester.pump(const Duration(milliseconds: 300));
    expect(captured, 'flutter');
  });

  testWidgets('Botón limpiar aparece cuando hay texto', (tester) async {
    await tester.pumpWidget(wrap(onChanged: (_) {}, onClear: () {}));
    expect(find.byKey(const Key('clearSearchBtn')), findsNothing);
    await tester.enterText(find.byKey(const Key('taskSearchField')), 'abc');
    await tester.pump();
    expect(find.byKey(const Key('clearSearchBtn')), findsOneWidget);
  });

  testWidgets('Botón limpiar limpia el campo y llama onClear', (tester) async {
    bool cleared = false;
    String? lastChanged;
    await tester.pumpWidget(
      wrap(onChanged: (v) => lastChanged = v, onClear: () => cleared = true),
    );
    await tester.enterText(find.byKey(const Key('taskSearchField')), 'abc');
    await tester.pump();
    await tester.tap(find.byKey(const Key('clearSearchBtn')));
    await tester.pump();
    expect(cleared, true);
    expect(lastChanged, '');
    expect(find.byKey(const Key('clearSearchBtn')), findsNothing);
  });
}
