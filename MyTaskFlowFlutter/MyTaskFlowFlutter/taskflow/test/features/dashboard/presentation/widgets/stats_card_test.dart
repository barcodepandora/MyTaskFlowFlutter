import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/features/dashboard/presentation/widgets/stats_card.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('Muestra label y valor numérico correctamente', (tester) async {
    await tester.pumpWidget(
      wrap(const StatsCard(label: 'Pendientes', value: '5', color: Colors.orange)),
    );
    expect(find.text('Pendientes'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('Muestra icono cuando se provee', (tester) async {
    await tester.pumpWidget(
      wrap(const StatsCard(
        label: 'Total',
        value: '10',
        color: Colors.blue,
        icon: Icons.checklist,
      )),
    );
    expect(find.byIcon(Icons.checklist), findsOneWidget);
  });

  testWidgets('No muestra icono cuando no se provee', (tester) async {
    await tester.pumpWidget(
      wrap(const StatsCard(label: 'Total', value: '10', color: Colors.blue)),
    );
    expect(find.byType(Icon), findsNothing);
  });
}
