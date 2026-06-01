import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/features/dashboard/presentation/widgets/completion_progress_bar.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('Barra al 0% muestra 0%', (tester) async {
    await tester.pumpWidget(wrap(const CompletionProgressBar(value: 0.0)));
    await tester.pumpAndSettle();
    expect(find.text('0% completado'), findsOneWidget);
  });

  testWidgets('Barra al 100% muestra 100%', (tester) async {
    await tester.pumpWidget(wrap(const CompletionProgressBar(value: 1.0)));
    await tester.pumpAndSettle();
    expect(find.text('100% completado'), findsOneWidget);
  });

  testWidgets('value entre 0 y 1 renderiza sin overflow', (tester) async {
    await tester.pumpWidget(wrap(const CompletionProgressBar(value: 0.5)));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('50% completado'), findsOneWidget);
  });
}
