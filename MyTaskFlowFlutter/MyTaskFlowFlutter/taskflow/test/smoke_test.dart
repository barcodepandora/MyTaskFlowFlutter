import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskflow/core/providers/theme_provider.dart';
import 'package:taskflow/features/auth/data/datasources/local_auth_datasource.dart';
import 'package:taskflow/features/auth/data/providers/auth_providers.dart';
import 'package:taskflow/features/tasks/data/datasources/in_memory_task_datasource.dart';
import 'package:taskflow/features/tasks/data/providers/tasks_providers.dart';
import 'package:taskflow/main.dart';

void main() {
  testWidgets('App smoke test — renders wrapped in ProviderScope', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final localAuth = LocalAuthDatasource();
    addTearDown(localAuth.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authRepositoryProvider.overrideWithValue(localAuth),
          taskRepositoryProvider.overrideWithValue(InMemoryTaskDatasource()),
        ],
        child: const TaskFlowApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
