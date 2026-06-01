import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskflow/core/widgets/loading_overlay.dart';

void main() {
  Widget buildOverlay({required bool isLoading}) {
    return MaterialApp(
      home: LoadingOverlay(
        isLoading: isLoading,
        child: const Text('Content'),
      ),
    );
  }

  group('LoadingOverlay', () {
    testWidgets('shows child content always', (tester) async {
      await tester.pumpWidget(buildOverlay(isLoading: false));

      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('does not show CircularProgressIndicator when not loading',
        (tester) async {
      await tester.pumpWidget(buildOverlay(isLoading: false));

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows CircularProgressIndicator when loading', (tester) async {
      await tester.pumpWidget(buildOverlay(isLoading: true));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows semi-transparent overlay when loading', (tester) async {
      await tester.pumpWidget(buildOverlay(isLoading: true));

      final container = tester.widget<Container>(find.byType(Container).last);
      final decoration = container.color;
      expect(decoration, Colors.black26);
    });

    testWidgets('shows both child and overlay when loading', (tester) async {
      await tester.pumpWidget(buildOverlay(isLoading: true));

      expect(find.text('Content'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
